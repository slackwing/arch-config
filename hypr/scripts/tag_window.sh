#!/usr/bin/env bash

TAGFILE=~/.cache/hypr_tag_window
WIN=$(hyprctl activewindow -j | jq -r '.address')

echo "$WIN" >"$TAGFILE"
notify-send "Tagged window" "$WIN"
