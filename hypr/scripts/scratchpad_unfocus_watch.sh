#!/usr/bin/env bash
# Hide any visible scratchpad when focus moves outside it (e.g. clicking
# another window). Listens on Hyprland's event socket; delegates the actual
# hide to scratchpad_toggle.sh so fullscreen-restore still applies.

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
TOGGLE="$HOME/.config/hypr/scripts/scratchpad_toggle.sh"

pad_of() {  # special workspace name -> toggle-script argument
    case "$1" in
        special:S-browser*) echo "${1#special:S-browser}" ;;
        special:S-sxiva)    echo 5 ;;
        special:S-term*)    echo "${1#special:S-term}" ;;
    esac
}

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
    [[ "$line" == activewindowv2\>\>* || "$line" == focusedmonv2\>\>* ]] || continue

    # Let dispatch batches (summon = toggle+focus+center) settle before
    # judging, then act on live state rather than the event payload.
    sleep 0.1

    mapfile -t specials < <(hyprctl monitors -j | jq -r \
        '.[].specialWorkspace.name | select(. != null) | select(startswith("special:S-"))')
    (( ${#specials[@]} )) || continue

    active_ws=$(hyprctl activewindow -j | jq -r '.workspace.name // ""')

    for ws in "${specials[@]}"; do
        [[ "$ws" == "$active_ws" ]] && continue
        n=$(pad_of "$ws")
        [[ -n "$n" ]] && "$TOGGLE" "$n"
    done
done
