#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"

FD_EXCLUDES=(
    --exclude .git --exclude node_modules --exclude __pycache__
    --exclude .cache --exclude .local --exclude .dotnet --exclude .pki
    --exclude .vscode-shared --exclude snap --exclude venv --exclude .venv
    --exclude .impeccable --exclude .claude --exclude .nix-profile
    --exclude .oh-my-bash
)

listing() {
    local base="$1" mode="$2"
    [ "$base" != "$HOME" ] && printf '  ..\n'
    [ "$base" != "$HOME" ] && printf '󰏌 Open this folder\n'

    if [ "$mode" = "search" ]; then
        printf '󰉓 Browse (level by level)\n'
        {
            fd --type d "${FD_EXCLUDES[@]}" --max-depth 6 --base-directory "$base" 2>/dev/null | sed 's|/*$|/|'
            fd --type f "${FD_EXCLUDES[@]}" --max-depth 6 --base-directory "$base" 2>/dev/null
        } | sort
    else
        printf ' Search (recursive)\n'
        {
            fd --type d "${FD_EXCLUDES[@]}" --max-depth 1 --base-directory "$base" 2>/dev/null | sed 's|/*$|/|' | sort
            fd --type f "${FD_EXCLUDES[@]}" --max-depth 1 --base-directory "$base" 2>/dev/null | sort
        }
    fi
}

open_with_menu() {
    local full="$1"
    local name="${full##*/}"

    local actions="󰨞 VS Code\n󰉋 File Manager\n Terminal (Ghostty)"
    [ -f "$full" ] && actions="󰈔 Default App\n$actions"

    chosen=$(echo -e "$actions" | $ROFI -dmenu -p "Open: $name" -i)
    [ -z "$chosen" ] && return

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
            local dir="$full"
            [ -f "$full" ] && dir="$(dirname "$full")"
            ghostty +new-window --working-directory="$dir" &>/dev/null &
            ;;
    esac
}

# Main loop
base="$HOME"
mode="search"

while true; do
    label="${base#$HOME/}"
    [ "$base" = "$HOME" ] && label="~"
    prompt=" $label"
    [ "$mode" = "search" ] && prompt=" $label"

    selected=$(listing "$base" "$mode" | $ROFI -dmenu -p "$prompt" -i)
    [ -z "$selected" ] && exit 0

    case "$selected" in
        "󰉓 Browse (level by level)")
            mode="browse"
            continue ;;
        " Search (recursive)")
            mode="search"
            continue ;;
        "󰏌 Open this folder")
            open_with_menu "$base"
            exit 0 ;;
        "  ..")
            parent=$(dirname "$base")
            if [ "$parent" = "$HOME" ] || [ "$parent" = "/" ]; then
                base="$HOME"
            else
                base="$parent"
            fi
            continue ;;
    esac

    clean="${selected%/}"
    full="$base/$clean"

    if [ -d "$full" ]; then
        base="$full"
        mode="browse"
    else
        open_with_menu "$full"
        exit 0
    fi
done
