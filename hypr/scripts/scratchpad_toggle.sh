#!/usr/bin/env bash
# Numpad scratchpads (numlock off). Each pad is "whichever window lives in
# special:S-<name>"; Hyprland's native special-workspace toggle fades it
# in/out (see the specialWorkspace animation + windowrules in hyprland.conf).
#   1/2/3  -> firefox windows (main profile)   [KP_End/KP_Down/KP_Next]
#   5      -> terminal running sxiva           [KP_Begin]
#   7/8/9  -> plain terminals                  [KP_Home/KP_Up/KP_Prior]
#   claude1..4 -> claude in ~/.config/my       [KP_Add/KP_Subtract/KP_Multiply/KP_Divide]
#   last   -> whichever pad was used last      [KP_Insert / 0]
#
# Every pad key is bound as "press <pad>" (bind) + "release <pad>" (bindr):
# keydown shows a hidden pad immediately (or hides a visible one — tap
# toggle); keyup hides it again only when the press was a show AND lasted
# >= HOLD_US — i.e. holding any pad key peeks it. Watchers and ALT+S call
# the bare "<pad>" toggle form, which is unchanged.
#
# "tile" [KP_Delete / .] adopts the visible (else last-used) pad: the window
# moves out of pad-land and tiles onto the focused monitor's workspace (its
# "home", recorded in a per-pad HOME_FILE). An adopted pad's key still
# summons it as the centered modal, and every dismiss path returns it to its
# home tile instead of just closing the overlay. "." again re-tiles it to
# wherever you are now; "." while on its home workspace un-adopts it back to
# a pure scratchpad.

MODE="${1:-1}"
LAST_FILE="$XDG_RUNTIME_DIR/hypr_scratchpad_last"
STATE="$XDG_RUNTIME_DIR/hypr_scratchpad_fs_restore"
HOLD_US=300000
URL="https://claude.ai/new"

resolve_special() {
    case "$1" in
        1|2|3)      SPECIAL="special:S-browser$1" ;;
        5)          SPECIAL="special:S-sxiva" ;;
        7|8|9)      SPECIAL="special:S-term$1" ;;
        claude[1-4]) SPECIAL="special:S-$1" ;;
        *)          exit 1 ;;
    esac
    # Presence of HOME_FILE = pad is adopted (lives tiled on a real
    # workspace). Contents: "<addr> <workspace dispatch target>".
    HOME_FILE="$XDG_RUNTIME_DIR/hypr_scratchpad_home_$1"
}

find_addr() {
    hyprctl clients -j | jq -r --arg ws "$SPECIAL" \
        '[.[] | select(.workspace.name == $ws)][0].address // empty'
}

find_pad_addr() {  # find_addr, but also finds an adopted (tiled) pad
    addr=$(find_addr)
    if [[ -z "$addr" && -f "$HOME_FILE" ]]; then
        local haddr
        read -r haddr _ < "$HOME_FILE"
        addr=$(hyprctl clients -j | jq -r --arg a "$haddr" \
            '.[] | select(.address == $a) | .address')
        [[ -z "$addr" ]] && rm -f "$HOME_FILE"  # pad window is gone
    fi
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

return_other_adopted() {
    # Showing a pad REPLACES any other pad overlay on the focused monitor —
    # Hyprland swaps the specials directly, so the replaced pad's hide path
    # never runs (and the unfocus watcher only sees still-visible specials).
    # An adopted pad would be stranded hidden in pad-land; return it to its
    # home tile before our overlay takes over. Locals only — must not
    # clobber $SPECIAL/$HOME_FILE/$addr of the pad being shown.
    local ws mode hf hws oaddr
    ws=$(hyprctl monitors -j | jq -r \
        '.[] | select(.focused) | .specialWorkspace.name | select(startswith("special:S-"))')
    [[ -z "$ws" || "$ws" == "$SPECIAL" ]] && return
    case "$ws" in
        special:S-browser*) mode="${ws#special:S-browser}" ;;
        special:S-sxiva)    mode=5 ;;
        special:S-term*)    mode="${ws#special:S-term}" ;;
        special:S-claude*)  mode="${ws#special:S-}" ;;
        *)                  return ;;
    esac
    hf="$XDG_RUNTIME_DIR/hypr_scratchpad_home_$mode"
    [[ -f "$hf" ]] || return
    read -r _ hws < "$hf"
    oaddr=$(hyprctl clients -j | jq -r --arg ws "$ws" \
        '[.[] | select(.workspace.name == $ws)][0].address // empty')
    [[ -n "$oaddr" && -n "$hws" ]] && hyprctl --batch \
        "dispatch movetoworkspacesilent $hws,address:$oaddr ; dispatch settiled address:$oaddr"
}

do_show() {  # needs $addr set and capture_fs done
    return_other_adopted
    if [[ -n "$fs_state" ]]; then
        printf '%s\n' "$fs_state" > "$STATE"
    else
        rm -f "$STATE"
    fi
    # Adopted pad currently tiled on a real workspace: pull it back into the
    # (hidden) special workspace first, so the float/resize/center below stay
    # invisible, and re-record its home so do_hide returns it where it was.
    local pre=""
    if [[ -f "$HOME_FILE" ]]; then
        local hws
        hws=$(hyprctl clients -j | jq -r --arg a "$addr" \
            '.[] | select(.address == $a) | .workspace
             | if (.name | startswith("special:")) then empty
               elif .id > 0 then (.id | tostring)
               else "name:" + .name end')
        if [[ -n "$hws" ]]; then
            echo "$addr $hws" > "$HOME_FILE"
            pre="dispatch movetoworkspacesilent $SPECIAL,address:$addr ; dispatch setfloating address:$addr ; "
        fi
    fi
    # Pre-size and pre-center on the focused monitor while still hidden, so
    # the reveal is a pure fade — no cross-monitor travel, no re-centering
    # after the fact. 80% of monitor, centered in the area below waybar.
    local mx my mw mh rl rt rr rb tw th
    read -r mx my mw mh rl rt rr rb < <(hyprctl monitors -j | jq -r \
        '.[] | select(.focused) | "\(.x) \(.y) \(.width) \(.height) \(.reserved[0]) \(.reserved[1]) \(.reserved[2]) \(.reserved[3])"')
    tw=$(( mw * 80 / 100 ))
    th=$(( mh * 80 / 100 ))
    hyprctl --batch "${pre}dispatch resizewindowpixel exact $tw $th,address:$addr ; dispatch movewindowpixel exact $(( mx + rl + (mw - rl - rr - tw) / 2 )) $(( my + rt + (mh - rt - rb - th) / 2 )),address:$addr"
    hyprctl --batch "dispatch togglespecialworkspace ${SPECIAL#special:} ; dispatch focuswindow address:$addr"
}

close_overlay() {
    # togglespecialworkspace acts on the FOCUSED monitor: if the pad is
    # showing on a different monitor, a bare toggle would summon it there
    # instead of closing it. Close it on the monitor that's showing it.
    local pad_mon cur_mon
    pad_mon=$(hyprctl monitors -j | jq -r --arg ws "$SPECIAL" \
        '.[] | select(.specialWorkspace.name == $ws) | .name' | head -1)
    cur_mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    if [[ -n "$pad_mon" && "$pad_mon" != "$cur_mon" ]]; then
        hyprctl --batch "dispatch focusmonitor $pad_mon ; dispatch togglespecialworkspace ${SPECIAL#special:} ; dispatch focusmonitor $cur_mon"
    else
        hyprctl dispatch togglespecialworkspace "${SPECIAL#special:}"
    fi
}

do_hide() {
    if [[ -f "$HOME_FILE" ]]; then
        # Adopted pad: dismissing returns the window to its home tile.
        # Emptying the special workspace normally closes the overlay by
        # itself; close it explicitly if Hyprland left it open.
        local hws haddr
        read -r _ hws < "$HOME_FILE"
        haddr=$(find_addr)
        [[ -n "$haddr" && -n "$hws" ]] && hyprctl --batch \
            "dispatch movetoworkspacesilent $hws,address:$haddr ; dispatch settiled address:$haddr"
        is_visible && close_overlay
    else
        close_overlay
    fi
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
        case "$MODE" in
            5)       cmd="alacritty -e zsh -ic 'sxiva; exec zsh'" ;;
            claude*) cmd="alacritty --working-directory $HOME/.config/my -e zsh -ic 'claude --dangerously-skip-permissions; exec zsh'" ;;
        esac
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
    press)
        RAW="$2"
        [[ -z "$RAW" ]] && exit 1
        MODE="$RAW"
        if [[ "$MODE" == "last" ]]; then
            MODE=$(cat "$LAST_FILE" 2>/dev/null)
            [[ -z "$MODE" ]] && exit 0
        fi
        resolve_special "$MODE"
        echo "$MODE" > "$LAST_FILE"
        PRESS_FILE="$XDG_RUNTIME_DIR/hypr_scratchpad_press_$RAW"
        if is_visible; then
            echo "hid" > "$PRESS_FILE"
            do_hide
        else
            echo "shown ${EPOCHREALTIME//[.,]/}" > "$PRESS_FILE"
            find_pad_addr
            capture_fs
            [[ -z "$addr" ]] && launch_pad
            do_show
        fi
        exit 0
        ;;
    tile)
        # Tile the visible pad (focused monitor first), else the last-used
        # one, onto the focused monitor's workspace — "adopting" it. "." on
        # a pad already tiled here un-adopts it back to a pure scratchpad;
        # on a pad tiled elsewhere, it re-tiles it here.
        MODE=$(hyprctl monitors -j | jq -r \
            '[.[] | select(.specialWorkspace.name | startswith("special:S-"))]
             | sort_by(if .focused then 0 else 1 end)
             | .[0].specialWorkspace.name // empty')
        case "$MODE" in
            special:S-browser*) MODE="${MODE#special:S-browser}" ;;
            special:S-sxiva)    MODE=5 ;;
            special:S-term*)    MODE="${MODE#special:S-term}" ;;
            special:S-claude*)  MODE="${MODE#special:S-}" ;;
            *)                  MODE=$(cat "$LAST_FILE" 2>/dev/null) ;;
        esac
        [[ -z "$MODE" ]] && exit 0
        resolve_special "$MODE"
        find_pad_addr
        [[ -z "$addr" ]] && exit 0
        echo "$MODE" > "$LAST_FILE"

        # Focused monitor's real (non-special) workspace, as both an id for
        # comparison and a ready-made dispatch target.
        read -r awsid aws < <(hyprctl monitors -j | jq -r \
            '.[] | select(.focused) | .activeWorkspace
             | "\(.id) " + (if .id > 0 then (.id | tostring) else "name:" + .name end)')
        read -r wsid wsname < <(hyprctl clients -j | jq -r --arg a "$addr" \
            '.[] | select(.address == $a) | "\(.workspace.id) \(.workspace.name)"')

        if [[ "$wsname" == special:* ]]; then
            # In pad-land (modal up, or hidden) -> adopt: tile it here. We
            # are tiling, not dismissing, so drop any pending fullscreen
            # restore — re-fullscreening would just cover the new tile.
            rm -f "$STATE"
            hyprctl --batch "dispatch movetoworkspacesilent $aws,address:$addr ; dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
            is_visible && close_overlay
            echo "$addr $aws" > "$HOME_FILE"
        elif [[ "$wsid" == "$awsid" ]]; then
            # Already tiled on this workspace -> un-adopt.
            hyprctl --batch "dispatch movetoworkspacesilent $SPECIAL,address:$addr ; dispatch setfloating address:$addr"
            rm -f "$HOME_FILE"
        else
            # Tiled on some other workspace -> bring its home here.
            hyprctl --batch "dispatch movetoworkspacesilent $aws,address:$addr ; dispatch settiled address:$addr ; dispatch focuswindow address:$addr"
            echo "$addr $aws" > "$HOME_FILE"
        fi
        exit 0
        ;;
    release)
        RAW="$2"
        [[ -z "$RAW" ]] && exit 1
        PRESS_FILE="$XDG_RUNTIME_DIR/hypr_scratchpad_press_$RAW"
        read -r action t < "$PRESS_FILE" 2>/dev/null || exit 0
        rm -f "$PRESS_FILE"
        [[ "$action" == "shown" ]] || exit 0
        (( ${EPOCHREALTIME//[.,]/} - t >= HOLD_US )) || exit 0
        MODE="$RAW"
        [[ "$MODE" == "last" ]] && MODE=$(cat "$LAST_FILE" 2>/dev/null)
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

find_pad_addr
capture_fs
[[ -z "$addr" ]] && launch_pad

if is_visible; then
    do_hide
else
    do_show
fi
