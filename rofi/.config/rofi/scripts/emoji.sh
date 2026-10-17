#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:$PATH"

EMOJI_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-emoji-list.txt"

# Download emoji list if not cached
if [ ! -f "$EMOJI_FILE" ]; then
    curl -fsSL "https://raw.githubusercontent.com/muan/emojilib/main/dist/emoji-en-US.json" 2>/dev/null | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
for emoji, keywords in data.items():
    print(f\"{emoji} {' '.join(keywords)}\")
" > "$EMOJI_FILE" 2>/dev/null
fi

if [ -z "$1" ]; then
    cat "$EMOJI_FILE" 2>/dev/null
else
    emoji=$(echo "$1" | cut -d' ' -f1)
    printf '%s' "$emoji" | wl-copy
fi
