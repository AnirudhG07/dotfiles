#!/usr/bin/env bash
# Hourly break reminder — only fires when user is active (idle < 5 min)
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

IDLE_THRESHOLD_MS=300000  # 5 minutes

idle_ms=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
    /org/gnome/Mutter/IdleMonitor/Core \
    org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
    awk '/uint64/ {print $2}')

if [ -z "$idle_ms" ]; then
    exit 0
fi

if [ "$idle_ms" -lt "$IDLE_THRESHOLD_MS" ]; then
    notify-send -u normal -i dialog-information "Time for a Break" \
        "You've been working for a while. Stand up, stretch, hydrate! 💧\n\nSuper+B to start a break timer."
fi
