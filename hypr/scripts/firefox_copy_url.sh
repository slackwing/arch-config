#!/usr/bin/env bash
# SUPER+SHIFT+C: copy the current URL from firefox's address bar.
# No external way to read the URL exists, so emulate the keystrokes with
# ydotool: Ctrl+L (focus address bar, URL selected), Ctrl+C, Esc back.

class=$(hyprctl activewindow -j | jq -r '.class')
[[ "$class" == "firefox" ]] || exit 0

# Give the physical SUPER+SHIFT time to be released so they don't combine
# with the injected keys. Increase if you tend to hold the combo longer.
sleep 0.25

ydotool key 29:1 38:1 38:0 29:0   # Ctrl+L
sleep 0.1
ydotool key 29:1 46:1 46:0 29:0   # Ctrl+C
sleep 0.1
ydotool key 1:1 1:0 1:1 1:0       # Esc x2: close dropdown, refocus page

notify-send -t 1500 "URL copied" "$(wl-paste 2>/dev/null | head -c 200)"
