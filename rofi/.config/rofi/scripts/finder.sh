#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"
STATE_FILE="/tmp/rofi-finder-selection"

FD_EXCLUDES=(
    --exclude .git --exclude node_modules --exclude __pycache__
    --exclude .cache --exclude .local --exclude .dotnet --exclude .pki
    --exclude .vscode-shared --exclude snap --exclude venv --exclude .venv
    --exclude .impeccable --exclude .claude --exclude .nix-profile
    --exclude .oh-my-bash
)

if [ -z "$1" ]; then
    # First call: list files and directories
    if [ -f "$STATE_FILE" ]; then
        rm "$STATE_FILE"
        # Second stage: show actions for the selected item
        selection=$(cat /tmp/rofi-finder-item)
        full="$HOME/$selection"

        actions="󰨞 VS Code\n󰉋 File Manager\n Terminal (Ghostty)"
        if [ -f "$full" ]; then
            actions="󰈔 Default App\n$actions"
        fi

        chosen=$(echo -e "$actions" | $ROFI -dmenu -p "Open: ${selection##*/}" -i)
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
        rm -f /tmp/rofi-finder-item
        exit 0
    fi

    # List both files and directories
    {
        fd --type d "${FD_EXCLUDES[@]}" --max-depth 5 --base-directory "$HOME" 2>/dev/null | sed 's|$|/|'
        fd --type f "${FD_EXCLUDES[@]}" --max-depth 6 --base-directory "$HOME" 2>/dev/null
    } | sort
else
    # Item selected — save it and re-trigger for action menu
    echo "$1" > /tmp/rofi-finder-item
    touch "$STATE_FILE"
    exec bash "$0"
fi
