#!/usr/bin/env bash
# Numpad scratchpads (numlock off). Each pad is "whichever window lives in
# special:S-<name>"; Hyprland's native special-workspace toggle fades it
# in/out (see the specialWorkspace animation + windowrules in hyprland.conf).
#   1/2/3  -> firefox windows (main profile)   [KP_End/KP_Down/KP_Next]
#   5      -> terminal running sxiva           [KP_Begin]
#   7/8/9  -> plain terminals                  [KP_Home/KP_Up/KP_Prior]
#   last   -> toggle whichever pad was used last        [KP_Insert / 0]
#   peek/unpeek -> hold-to-show the last pad   [KP_Delete / . via bind+bindr]

MODE="${1:-1}"
LAST_FILE="$XDG_RUNTIME_DIR/hypr_scratchpad_last"
STATE="$XDG_RUNTIME_DIR/hypr_scratchpad_fs_restore"
PEEK_FLAG="$XDG_RUNTIME_DIR/hypr_scratchpad_peek"
URL="https://claude.ai/new"

resolve_special() {
    case "$1" in
        1|2|3) SPECIAL="special:S-browser$1" ;;
        5)     SPECIAL="special:S-sxiva" ;;
        7|8|9) SPECIAL="special:S-term$1" ;;
        *)     exit 1 ;;
    esac
}

find_addr() {
    hyprctl clients -j | jq -r --arg ws "$SPECIAL" \
        '[.[] | select(.workspace.name == $ws)][0].address // empty'
}

is_visible() {
    (( $(hyprctl monitors -j | jq --arg ws "$SPECIAL" \
        '[.[] | select(.specialWorkspace.name == $ws)] | length') > 0 ))
}

# Capture any fullscreen window on the current workspace BEFORE creating or
# revealing anything — both a newly created window and the special-workspace
# overlay can cancel fullscreen, and we want the pre-existing state.
capture_fs() {
    fs_state=$(hyprctl clients -j | jq -r \
        --argjson ws "$(hyprctl activeworkspace -j | jq '.id')" \
        '[.[] | select(.workspace.id == $ws and .fullscreen != 0)][0]
         | if . == null then empty else "\(.address) \(.fullscreen)" end')
}

do_show() {  # needs $addr set and capture_fs done
    if [[ -n "$fs_state" ]]; then
        printf '%s\n' "$fs_state" > "$STATE"
    else
        rm -f "$STATE"
    fi
    # Show, focus, and re-center on this monitor (centerwindow's argument
    # makes it respect waybar's reserved strip).
    hyprctl --batch "dispatch togglespecialworkspace ${SPECIAL#special:} ; dispatch focuswindow address:$addr ; dispatch centerwindow 1"
}

do_hide() {
    hyprctl dispatch togglespecialworkspace "${SPECIAL#special:}"
    # Restore fullscreen we broke when summoning (Hyprland un-fullscreens
    # under a special-workspace overlay; see hyprwm/Hyprland#6820).
    if [[ -f "$STATE" ]]; then
        read -r fs_addr fs_mode < "$STATE"
        rm -f "$STATE"
        local cur active
        cur=$(hyprctl clients -j | jq -r --arg a "$fs_addr" \
            '.[] | select(.address == $a) | .fullscreen')
        active=$(hyprctl activewindow -j | jq -r '.address // ""')
        # Only restore when focus came back to the window we un-fullscreened
        # (keybind dismiss). If the user clicked a different window (unfocus
        # hide), don't steal their focus just to re-fullscreen it.
        if [[ "$cur" == "0" && "$active" == "$fs_addr" ]]; then
            hyprctl dispatch fullscreenstate "$fs_mode" -1
        fi
    fi
}

launch_pad() {  # creates the pad window for $MODE/$SPECIAL, sets $addr
    if [[ "$MODE" == [123] ]]; then
        # Firefox: exec window-rules can't target the new window (firefox
        # forwards to the running process, so the spawned PID never owns it)
        # — diff window addresses to catch it, then float/size/stash.
        local before
        before=$(hyprctl clients -j | jq -r \
            '[.[] | select(.class == "firefox") | .address] | @json')
        hyprctl dispatch exec "firefox --new-window $URL"
        addr=""
        for _ in $(seq 1 50); do
            addr=$(hyprctl clients -j | jq -r --argjson b "$before" \
                '[.[] | select(.class == "firefox") | .address | select(. as $a | $b | index($a) | not)][0] // empty')
            [[ -n "$addr" ]] && break
            sleep 0.1
        done
        [[ -z "$addr" ]] && exit 1
        hyprctl --batch "dispatch setfloating address:$addr ; dispatch resizewindowpixel exact 80% 80%,address:$addr ; dispatch movetoworkspacesilent $SPECIAL,address:$addr"
    else
        # Terminals own their window PID, so exec rules place them directly
        # in the (hidden) special workspace — no flash. Pad 5 goes through an
        # interactive zsh: Hyprland's env lacks SXIVA_DATA/EDITOR, and when
        # sxiva exits the pad stays a usable shell instead of closing.
        local cmd="alacritty"
        [[ "$MODE" == "5" ]] && cmd="alacritty -e zsh -ic 'sxiva; exec zsh'"
        hyprctl dispatch exec "[float; workspace $SPECIAL silent] $cmd"
        for _ in $(seq 1 50); do
            addr=$(find_addr)
            [[ -n "$addr" ]] && break
            sleep 0.1
        done
        [[ -z "$addr" ]] && exit 1
        # exec-rule size percentages are unreliable; size explicitly to
        # match the browser pads.
        hyprctl dispatch resizewindowpixel "exact 80% 80%,address:$addr"
    fi
}

case "$MODE" in
    peek)
        # Hold-to-show: only if the last pad exists and is hidden.
        [[ -f "$PEEK_FLAG" ]] && exit 0
        MODE=$(cat "$LAST_FILE" 2>/dev/null)
        [[ -z "$MODE" ]] && exit 0
        resolve_special "$MODE"
        addr=$(find_addr)
        [[ -z "$addr" ]] && exit 0
        is_visible && exit 0
        capture_fs
        touch "$PEEK_FLAG"
        do_show
        exit 0
        ;;
    unpeek)
        [[ -f "$PEEK_FLAG" ]] || exit 0
        rm -f "$PEEK_FLAG"
        MODE=$(cat "$LAST_FILE" 2>/dev/null)
        [[ -z "$MODE" ]] && exit 0
        resolve_special "$MODE"
        is_visible && do_hide
        exit 0
        ;;
    last)
        MODE=$(cat "$LAST_FILE" 2>/dev/null)
        [[ -z "$MODE" ]] && exit 0
        ;;
esac

resolve_special "$MODE"
echo "$MODE" > "$LAST_FILE"

addr=$(find_addr)
capture_fs
[[ -z "$addr" ]] && launch_pad

if is_visible; then
    do_hide
else
    do_show
fi
