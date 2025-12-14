#!/usr/bin/env bash

TAGFILE=~/.cache/hypr_tag_sxiva
WIN=$(hyprctl activewindow -j | jq -r '.address')

echo "$WIN" >"$TAGFILE"
notify-send "SXIVA window tagged!" "$WIN"
