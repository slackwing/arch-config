#!/usr/bin/env bash
# Waybar weather pill: outside temp for ZIP 11206 via wttr.in.
# Fetches (both units) at most every 5 minutes; the 5s waybar interval
# alternates the displayed unit, so it cycles C/F without re-fetching.

ZIP=11206
CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar_weather_$ZIP"
MAX_AGE=300

now=$(date +%s)
if [[ ! -f "$CACHE" ]] || (( now - $(stat -c %Y "$CACHE") > MAX_AGE )); then
    # wttr.in prefixes an explicit sign; drop the "+", keep "-" for below zero.
    c=$(curl -sf --max-time 5 "wttr.in/$ZIP?m&format=%c%t" | tr -d '+')
    f=$(curl -sf --max-time 5 "wttr.in/$ZIP?u&format=%c%t" | tr -d '+')
    # Only overwrite on success so a flaky fetch keeps showing stale data.
    if [[ -n "$c" && -n "$f" ]]; then
        printf '%s\n%s\n' "$c" "$f" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
    fi
fi

[[ -f "$CACHE" ]] || exit 0
mapfile -t lines < "$CACHE"

if (( (now / 5) % 2 )); then
    echo "${lines[1]}"   # fahrenheit
else
    echo "${lines[0]}"   # celsius
fi
