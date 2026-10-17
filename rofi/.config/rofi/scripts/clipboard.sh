#!/usr/bin/env bash
# Restore WAYLAND_DISPLAY so wl-copy/wl-paste work
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

CLIP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-clipboard"
CLIP_MAX=50

mkdir -p "$CLIP_DIR"

save_clip() {
    local content
    content=$(wl-paste --no-newline 2>/dev/null) || return
    [ -z "$content" ] && return
    local hash
    hash=$(echo -n "$content" | md5sum | cut -d' ' -f1)
    printf '%s' "$content" > "$CLIP_DIR/$hash"
    touch "$CLIP_DIR/$hash"
    ls -1t "$CLIP_DIR" 2>/dev/null | tail -n +$((CLIP_MAX + 1)) | while read -r f; do
        rm -f "$CLIP_DIR/$f"
    done
}

if [ -z "$1" ]; then
    save_clip
    for f in $(ls -1t "$CLIP_DIR" 2>/dev/null); do
        head -c 200 "$CLIP_DIR/$f" | tr '\n' ' '
        echo
    done
    [ ! "$(ls -A "$CLIP_DIR" 2>/dev/null)" ] && echo "(clipboard empty)"
else
    for f in $(ls -1t "$CLIP_DIR" 2>/dev/null); do
        display=$(head -c 200 "$CLIP_DIR/$f" | tr '\n' ' ')
        if [ "$display" = "$1" ]; then
            wl-copy < "$CLIP_DIR/$f"
            break
        fi
    done
fi
