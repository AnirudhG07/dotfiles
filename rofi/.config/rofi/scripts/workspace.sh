#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

CONF="$HOME/.config/rofi/workspaces.conf"
ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"

touch "$CONF"

get_entries() {
    grep -v '^[[:space:]]*#' "$CONF" | grep -v '^[[:space:]]*$'
}

is_running() {
    local cmd="$1"
    local binary="${cmd%% *}"
    local args="${cmd#* }"
    args="${args/#\~/$HOME}"

    case "$binary" in
        code)
            # Check if VS Code has this specific directory open
            pgrep -f "code.*${args}" &>/dev/null
            ;;
        brave-browser|firefox|chromium)
            pgrep -f "$binary" &>/dev/null
            ;;
        ghostty)
            pgrep -f "ghostty" &>/dev/null
            ;;
        *)
            pgrep -f "$binary" &>/dev/null
            ;;
    esac
}

launch_workspace() {
    local launched=0 skipped=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if is_running "$line"; then
            ((skipped++))
        else
            local expanded="${line/#\~/$HOME}"
            eval "$expanded" &>/dev/null &
            ((launched++))
        fi
    done < "$CONF"
    notify-send "Workspace" "Launched $launched, skipped $skipped (already open)" -t 2000
}

# Main menu
action=$(printf "▶ Launch workspace\n+ Add directory (opens as VS Code)\n+ Add custom command\n✎ Edit config in terminal\n─────────\n$(get_entries | sed 's/^/✗ Remove: /')" | \
    $ROFI -dmenu -p "⚡ Workspace" -i)

[ -z "$action" ] && exit 0

case "$action" in
    "▶ Launch workspace")
        launch_workspace
        ;;
    "+ Add directory (opens as VS Code)")
        dir=$(fd --type d --max-depth 4 --base-directory "$HOME" 2>/dev/null | \
            $ROFI -dmenu -p " Pick dir" -i)
        [ -z "$dir" ] && exit 0
        echo "code ~/$dir" >> "$CONF"
        notify-send "Workspace" "Added: code ~/$dir" -t 2000
        ;;
    "+ Add custom command")
        cmd=$($ROFI -dmenu -p " Command" -i -lines 0)
        [ -z "$cmd" ] && exit 0
        echo "$cmd" >> "$CONF"
        notify-send "Workspace" "Added: $cmd" -t 2000
        ;;
    "✎ Edit config in terminal")
        ghostty -e zsh -ic "nvim $CONF" &
        ;;
    "✗ Remove: "*)
        entry="${action#✗ Remove: }"
        escaped=$(printf '%s\n' "$entry" | sed 's/[[\.*^$()+?{|]/\\&/g')
        sed -i "\|^${escaped}$|d" "$CONF"
        notify-send "Workspace" "Removed: $entry" -t 2000
        ;;
esac
