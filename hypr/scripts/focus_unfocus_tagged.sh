#!/usr/bin/env bash

TAGFILE=~/.cache/hypr_tag_window
OTHERFILE=~/.cache/hypr_other_window

# Ensure a tag exists
[[ ! -f "$TAGFILE" ]] && notify-send "No tagged window set" && exit 1

TAG=$(cat "$TAGFILE")
CURRENT=$(hyprctl activewindow -j | jq -r '.address')

# If we're on the tagged window -> jump to OTHER
if [[ "$CURRENT" == "$TAG" ]]; then
    if [[ -f "$OTHERFILE" ]]; then
        OTHER=$(cat "$OTHERFILE")
        hyprctl dispatch focuswindow address:$OTHER
    fi
    exit 0
fi

# If we're on another window -> store OTHER and jump to TAG
echo "$CURRENT" >"$OTHERFILE"
hyprctl dispatch focuswindow address:$TAG
