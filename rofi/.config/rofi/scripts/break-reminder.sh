#!/usr/bin/env bash
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

IDLE_THRESHOLD_MS=300000  # 5 minutes
BREAK_MINS=3
ROFI="env WAYLAND_DISPLAY= /usr/local/bin/rofi -normal-window"
SNOOZE_FILE="/tmp/rofi-break-snooze"

# Check for active snooze
if [ -f "$SNOOZE_FILE" ]; then
    snooze_until=$(cat "$SNOOZE_FILE")
    now=$(date +%s)
    if [ "$now" -lt "$snooze_until" ]; then
        exit 0
    fi
    rm -f "$SNOOZE_FILE"
fi

# Check idle time
idle_ms=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
    /org/gnome/Mutter/IdleMonitor/Core \
    org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
    awk '/uint64/ {print $2}')

if [ -z "$idle_ms" ] || [ "$idle_ms" -ge "$IDLE_THRESHOLD_MS" ]; then
    exit 0
fi

# Launch the break screen directly (3 min)
notify-send "Break Time" "Starting a $BREAK_MINS minute break. Relax!" -t 3000

secs=$((BREAK_MINS * 60))

python3 - "$secs" "$BREAK_MINS" <<'PYEOF'
import sys, time, signal, os
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

total = int(sys.argv[1])
mins_label = sys.argv[2]
remaining = total
escaped = False

class BreakWindow(Gtk.Window):
    def fetch_quote(self):
        import urllib.request, json
        fallbacks = [
            "The only way to do great work is to love what you do. — Steve Jobs",
            "In the middle of difficulty lies opportunity. — Albert Einstein",
            "Rest is not idleness. — John Lubbock",
        ]
        try:
            req = urllib.request.Request("https://zenquotes.io/api/random", headers={"User-Agent": "breaktime"})
            with urllib.request.urlopen(req, timeout=3) as r:
                data = json.loads(r.read())
                return f'"{data[0]["q"]}"\n— {data[0]["a"]}'
        except Exception:
            import random
            return random.choice(fallbacks)

    def __init__(self):
        super().__init__(title="Break Time")
        self.set_decorated(False)
        self.fullscreen()

        screen = Gdk.Screen.get_default()
        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window { background: #1e1e2e; }
            .title { font-size: 72px; color: #89b4fa; font-weight: bold; }
            .timer { font-size: 120px; color: #cdd6f4; font-weight: bold; font-family: monospace; }
            .msg { font-size: 28px; color: #7f849c; }
            .skip { font-size: 18px; color: #45475a; margin-top: 40px; }
        """)
        Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_valign(Gtk.Align.CENTER)
        box.set_halign(Gtk.Align.CENTER)

        title = Gtk.Label(label="Take a Break")
        title.get_style_context().add_class("title")

        self.timer_label = Gtk.Label()
        self.timer_label.get_style_context().add_class("timer")

        quote_text = self.fetch_quote()
        msg = Gtk.Label(label=quote_text)
        msg.get_style_context().add_class("msg")
        msg.set_line_wrap(True)
        msg.set_max_width_chars(60)
        msg.set_justify(Gtk.Justification.CENTER)

        skip = Gtk.Label(label="Press Escape to snooze")
        skip.get_style_context().add_class("skip")

        box.pack_start(title, False, False, 0)
        box.pack_start(self.timer_label, False, False, 0)
        box.pack_start(msg, False, False, 0)
        box.pack_start(skip, False, False, 0)

        self.add(box)
        self.connect("key-press-event", self.on_key)
        self.update_timer()
        GLib.timeout_add(1000, self.tick)

    def update_timer(self):
        global remaining
        m, s = divmod(remaining, 60)
        self.timer_label.set_text(f"{m:02d}:{s:02d}")

    def tick(self):
        global remaining
        remaining -= 1
        if remaining <= 0:
            Gtk.main_quit()
            return False
        self.update_timer()
        return True

    def on_key(self, widget, event):
        global escaped
        if event.keyval == Gdk.KEY_Escape:
            escaped = True
            Gtk.main_quit()

win = BreakWindow()
win.show_all()
signal.signal(signal.SIGTERM, lambda *a: Gtk.main_quit())
Gtk.main()

sys.exit(1 if escaped else 0)
PYEOF

exit_code=$?

if [ "$exit_code" -eq 1 ]; then
    # Escaped — show snooze picker
    snooze=$(printf "5 minutes\n10 minutes\n15 minutes\n30 minutes\n60 minutes\nCustom..." | \
        $ROFI -dmenu -p "⏰ Snooze for" -i)

    [ -z "$snooze" ] && exit 0

    if [ "$snooze" = "Custom..." ]; then
        mins=$($ROFI -dmenu -p "Minutes" -i -lines 0)
        [ -z "$mins" ] && exit 0
        if ! [[ "$mins" =~ ^[0-9]+$ ]] || [ "$mins" -eq 0 ]; then
            notify-send "Snooze" "Invalid number" -t 2000
            exit 1
        fi
        snooze="$mins minutes"
    else
        mins="${snooze%% *}"
    fi

    snooze_until=$(( $(date +%s) + mins * 60 ))
    echo "$snooze_until" > "$SNOOZE_FILE"
    # Schedule a one-shot timer to re-trigger after snooze
    systemd-run --user --on-active="${mins}m" --unit=break-snooze \
        bash "$HOME/.config/rofi/scripts/break-reminder.sh" 2>/dev/null
    notify-send "Break Snoozed" "Next break in $snooze" -t 3000
else
    notify-send "Break Over" "Welcome back! 💪" -t 3000
fi
