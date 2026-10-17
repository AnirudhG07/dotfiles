#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:$PATH"

if [ -z "$1" ]; then
    fd --type f \
        --exclude .git \
        --exclude node_modules \
        --exclude __pycache__ \
        --exclude .cache \
        --exclude .local \
        --exclude .dotnet \
        --exclude .pki \
        --exclude .vscode-shared \
        --exclude snap \
        --exclude venv \
        --exclude .venv \
        --exclude .impeccable \
        --exclude .claude \
        --exclude .nix-profile \
        --exclude .oh-my-bash \
        --max-depth 6 \
        --base-directory "$HOME" 2>/dev/null
else
    xdg-open "$HOME/$1" 2>/dev/null &
fi
