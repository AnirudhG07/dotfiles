#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"

DBUS_DEST="org.gnome.Shell"
DBUS_PATH="/org/rofi/WindowSwitcher"
DBUS_IFACE="org.rofi.WindowSwitcher"

windows_json=$(gdbus call --session --dest "$DBUS_DEST" \
    --object-path "$DBUS_PATH" \
    --method "$DBUS_IFACE.List" 2>/dev/null)

if [ -z "$windows_json" ]; then
    notify-send "Window Picker" "Extension not available. Log out and back in to activate it." -t 5000
    exit 1
fi

# gdbus wraps output in ('...',) — extract the JSON string
json=$(echo "$windows_json" | sed "s/^('//;s/',)$//;s/\\\\'/'/g")

count=$(echo "$json" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
if [ "$count" = "0" ] || [ -z "$count" ]; then
    notify-send "Window Picker" "No windows open" -t 2000
    exit 0
fi

# Build rofi menu: "app — title [ws N]"
entries=$(echo "$json" | python3 -Ic "
import sys, json
ICONS = {
    'Visual Studio Code': '\U000F0A1E',
    'Code': '\U000F0A1E',
    'Brave Web Browser': '\U000F059F',
    'Brave': '\U000F059F',
    'Firefox': '\U000F0239',
    'Google Chrome': '\U000F035A',
    'Chromium': '\U000F035A',
    'Ghostty': '\U000F0489',
    'Terminal': '\U000F0489',
    'Nautilus': '\U000F024B',
    'Files': '\U000F024B',
    'Spotify': '\U000F04C7',
    'Discord': '\U000F066F',
    'Slack': '\U000F04B1',
    'Telegram': '\U000F0531',
    'Thunderbird': '\U000F01EE',
    'Rofi': '\U000F0140',
    'Settings': '\U000F0493',
    'Zotero': '\U000F00FA',
    'VLC': '\U000F057C',
}
wins = json.load(sys.stdin)
for w in wins:
    icon = ICONS.get(w['app'], '')
    focused = ' *' if w['focused'] else ''
    print(f'{w[\"id\"]}|{icon} {w[\"app\"]} — {w[\"title\"]} [ws {w[\"ws\"] + 1}]{focused}')
")

menu=$(echo "$entries" | cut -d'|' -f2-)

selected=$(echo "$menu" | $ROFI -dmenu -p "󰖯 Windows" -i -no-show-icons)
[ -z "$selected" ] && exit 0

# Find the matching window id
win_id=$(echo "$entries" | grep -F "|$selected" | head -1 | cut -d'|' -f1)
[ -z "$win_id" ] && exit 1

gdbus call --session --dest "$DBUS_DEST" \
    --object-path "$DBUS_PATH" \
    --method "$DBUS_IFACE.Activate" "$win_id" &>/dev/null
