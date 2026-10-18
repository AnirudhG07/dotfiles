#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"
BASE_DIR_FILE="/tmp/rofi-finder-basedir"
ACTION_FILE="/tmp/rofi-finder-action"

FD_EXCLUDES=(
    --exclude .git --exclude node_modules --exclude __pycache__
    --exclude .cache --exclude .local --exclude .dotnet --exclude .pki
    --exclude .vscode-shared --exclude snap --exclude venv --exclude .venv
    --exclude .impeccable --exclude .claude --exclude .nix-profile
    --exclude .oh-my-bash
)

open_with_menu() {
    local full="$1"
    local label="${full#$HOME/}"

    actions="󰨞 VS Code\n󰉋 File Manager\n Terminal (Ghostty)"
    if [ -f "$full" ]; then
        actions="󰈔 Default App\n$actions"
    fi

    chosen=$(echo -e "$actions" | $ROFI -dmenu -p "Open: ${label##*/}" -i)
    [ -z "$chosen" ] && exit 0

    case "$chosen" in
        *"Default App"*)  xdg-open "$full" &>/dev/null & ;;
        *"VS Code"*)      code "$full" &>/dev/null & ;;
        *"File Manager"*)
            if [ -d "$full" ]; then
                xdg-open "$full" &>/dev/null &
            else
                xdg-open "$(dirname "$full")" &>/dev/null &
            fi ;;
        *"Terminal"*)
            dir="$full"
            [ -f "$full" ] && dir="$(dirname "$full")"
            ghostty -e zsh -c "cd '$dir' && exec zsh" &>/dev/null &
            ;;
    esac
}

if [ -z "$1" ]; then
    if [ -f "$ACTION_FILE" ]; then
        # Action stage: open the selected item
        rm -f "$ACTION_FILE"
        selection=$(cat /tmp/rofi-finder-item)
        rm -f /tmp/rofi-finder-item "$BASE_DIR_FILE"
        open_with_menu "$selection"
        exit 0
    fi

    # Listing stage: show contents of current base directory
    base="$HOME"
    [ -f "$BASE_DIR_FILE" ] && base=$(cat "$BASE_DIR_FILE")

    prefix="${base#$HOME/}"
    [ "$base" = "$HOME" ] && prefix=""

    # .. to go up (unless at $HOME)
    [ "$base" != "$HOME" ] && echo "  .."

    # List dirs then files in current base
    {
        fd --type d "${FD_EXCLUDES[@]}" --max-depth 1 --base-directory "$base" 2>/dev/null | sed 's|/*$|/|' | sort
        fd --type f "${FD_EXCLUDES[@]}" --max-depth 1 --base-directory "$base" 2>/dev/null | sort
    }
else
    selected="$1"

    base="$HOME"
    [ -f "$BASE_DIR_FILE" ] && base=$(cat "$BASE_DIR_FILE")

    # Go up
    if [ "$selected" = "  .." ]; then
        parent=$(dirname "$base")
        if [ "$parent" = "$HOME" ] || [ "$parent" = "/" ]; then
            rm -f "$BASE_DIR_FILE"
        else
            echo "$parent" > "$BASE_DIR_FILE"
        fi
        exec bash "$0"
    fi

    # Strip trailing slash for path resolution
    clean="${selected%/}"
    full="$base/$clean"

    if [ -d "$full" ]; then
        # Drill into directory
        echo "$full" > "$BASE_DIR_FILE"
        exec bash "$0"
    else
        # File selected — show action menu
        echo "$full" > /tmp/rofi-finder-item
        touch "$ACTION_FILE"
        exec bash "$0"
    fi
fi
