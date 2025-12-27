#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"

latest_png="$(
    find "$DIR" -maxdepth 1 -type f -iname '*.png' -printf '%T@ %p\0' 2>/dev/null |
        sort -z -nr |
        head -z -n 1 |
        tr -d '\0' |
        cut -d' ' -f2-
)"

if [[ -z "${latest_png:-}" ]]; then
    command -v notify-send >/dev/null 2>&1 &&
        notify-send "Claude image command" "No PNG screenshots found in $DIR"
    exit 1
fi

# Copy to clipboard (Wayland)
printf '%s' "$latest_png" | wl-copy

# Optional notification
command -v notify-send >/dev/null 2>&1 &&
    notify-send "Claude image command" "Copied /Image command to clipboard"
