#!/usr/bin/env bash
# Set up GNOME keybindings for rofi 2.0
# Run once: bash ~/.config/rofi/scripts/setup-keybindings.sh

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# Free keys from GNOME defaults
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['XF86Keyboard']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift>XF86Keyboard']"
gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.shell.keybindings toggle-overview "['']"
gsettings set org.gnome.shell.keybindings toggle-quick-settings "['']"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['']"
gsettings set org.gnome.shell.keybindings toggle-application-view "['']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['']"
gsettings set org.freedesktop.ibus.general.hotkey triggers "['']" 2>/dev/null
dconf write /desktop/ibus/general/hotkey/triggers "['Control+space']" 2>/dev/null
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock "['XF86RotationLockToggle']"
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock-static "['XF86RotationLockToggle']"

# Center rofi windows
gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true

ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"

bindings=(
    "App Launcher|$ROFI -show drun|<Super>space"
    "Run Prompt|$ROFI -show run -run-command 'ghostty -e zsh -ic \"{cmd}; echo; echo Press enter to close; read\"'|<Super>r"
    "Find|$ROFI -show find|<Super>f"
    "Emoji|$ROFI -show emoji|<Super>e"
    "Workspace|env WAYLAND_DISPLAY= bash $HOME/.config/rofi/scripts/workspace.sh|<Super>w"
    "Clipboard|$ROFI -show clipboard|<Super>c"
    "Power Menu|$ROFI -show power|<Super>BackSpace"
    "SSH|$ROFI -show ssh|<Super>s"
    "Break Time|bash $HOME/.config/rofi/scripts/breaktime.sh|<Super>b"
)

paths=()
for i in "${!bindings[@]}"; do
    IFS='|' read -r name cmd key <<< "${bindings[$i]}"
    path="$BASE/custom$i/"
    paths+=("'$path'")
    gsettings set "$CUSTOM:$path" name "$name"
    gsettings set "$CUSTOM:$path" command "$cmd"
    gsettings set "$CUSTOM:$path" binding "$key"
    echo "  $key -> $name"
done

gsettings set "$SCHEMA" custom-keybindings "[$(IFS=,; echo "${paths[*]}")]"

echo ""
echo "Done! Keybindings:"
echo "  Super+Space      App launcher"
echo "  Super+R          Run prompt"
echo "  Super+F          Find (files & dirs)"
echo "  Super+C          Clipboard history"
echo "  Super+BackSpace  Power menu"
echo "  Super+W          Launch workspace"
echo "  Super+E          Emoji picker"
echo "  Super+S          SSH"
