#!/usr/bin/env bash

LED="/sys/class/leds/white:kbd_backlight/brightness"

# Read current brightness (strip whitespace)
current=$(cat "$LED" | tr -d '[:space:]')

if [[ "$current" == "0" ]]; then
    echo 255 >"$LED"
else
    echo 0 >"$LED"
fi
