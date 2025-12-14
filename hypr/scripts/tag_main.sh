#!/usr/bin/env bash

TAGFILE=~/.cache/hypr_tag_main
WIN=$(hyprctl activewindow -j | jq -r '.address')

echo "$WIN" >"$TAGFILE"
notify-send "Main window tagged!" "$WIN"
