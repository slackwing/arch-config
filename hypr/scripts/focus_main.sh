#!/usr/bin/env bash

SXIVA_FILE=~/.cache/hypr_tag_sxiva
MAIN_FILE=~/.cache/hypr_tag_main
PREV_FILE=~/.cache/hypr_tag_prev
THIS_FILE=$MAIN_FILE
THAT_FILE=$SXIVA_FILE

# Ensure a tag exists
[[ ! -f "$THIS_FILE" ]] && notify-send "No window tagged." && exit 1

THIS_TAG=$(cat "$THIS_FILE")
THAT_TAG=$(cat "$THAT_FILE")
CURRENT=$(hyprctl activewindow -j | jq -r '.address')

# If we're on the tagged window -> jump to PREV
if [[ "$CURRENT" == "$THIS_TAG" ]]; then
    if [[ -f "$PREV_FILE" ]]; then
        PREV_TAG=$(cat "$PREV_FILE")
        hyprctl dispatch focuswindow address:$PREV_TAG
    fi
else
    # If we're on another window -> store PREV and jump to THIS_TAG
    if [[ "$CURRENT" != "$THIS_TAG" && "$CURRENT" != "$THAT_TAG" ]]; then
        echo "$CURRENT" >"$PREV_FILE"
        notify-send "SET PREV FILE TO " "$CURRENT"
    fi
    hyprctl dispatch focuswindow address:$THIS_TAG
fi
