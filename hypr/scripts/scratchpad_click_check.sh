#!/usr/bin/env bash
# Fired by a non-consuming left-click bind (bindn): if a scratchpad is
# visible and the click landed outside its window, hide it. Complements
# scratchpad_unfocus_watch.sh, which handles keyboard focus changes.

specials=$(hyprctl monitors -j | jq -r \
    '.[].specialWorkspace.name | select(startswith("special:S-"))')
[[ -z "$specials" ]] && exit 0

read -r cx cy < <(hyprctl cursorpos -j | jq -r '"\(.x) \(.y)"')

while read -r ws; do
    [[ -z "$ws" ]] && continue
    read -r x y w h < <(hyprctl clients -j | jq -r --arg ws "$ws" \
        '[.[] | select(.workspace.name == $ws)][0] | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"')
    [[ -z "$x" || "$x" == "null" ]] && continue
    if (( cx < x || cx > x + w || cy < y || cy > y + h )); then
        case "$ws" in
            special:S-browser*) n="${ws#special:S-browser}" ;;
            special:S-sxiva)    n=5 ;;
            special:S-term*)    n="${ws#special:S-term}" ;;
            special:S-claude*)  n="${ws#special:S-}" ;;
            *)                  continue ;;
        esac
        "$HOME/.config/hypr/scripts/scratchpad_toggle.sh" "$n"
    fi
done <<< "$specials"
