#!/bin/bash
# Reset the Ryzen HD Audio controller and its Conexant codec in place (no
# reboot) by unbinding/rebinding the PCI device. Use when the codec hangs:
# /proc/asound/card1/codec#0 shows "Invalid AFG subtree" (zero "Node"
# lines) and "Power: setting=UNKNOWN ... Error", dmesg fills with
# "azx_single_wait_for_response: N callbacks suppressed", the speakers pop
# or blare square-wave tones, and waybar shows a headphone icon with
# nothing plugged in (jack detection reads garbage). First seen 2026-11-09.
# PipeWire sees the card leave and return like a USB device; streams resume.
#
#   sudo bash ~/.config/my/hda-reset.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

DEV=$(lspci -D | awk '/Audio device:.*Ryzen HD Audio/{print $1; exit}')
[[ -n $DEV ]] || { echo "no Ryzen HD Audio controller found" >&2; exit 1; }
DRV=/sys/bus/pci/drivers/snd_hda_intel

show() {
  for f in /proc/asound/card*/codec#*; do
    grep -q Conexant "$f" 2>/dev/null || continue
    echo "$f: $(grep -c '^Node' "$f") nodes; $(grep -m1 'Power:' "$f" | sed 's/^ *//')"
  done
}
echo "== before =="; show
echo "== rebinding $DEV =="
[[ -e $DRV/$DEV ]] && { echo "$DEV" > "$DRV/unbind"; sleep 1; } || echo "(was not bound)"
echo "$DEV" > "$DRV/bind"; sleep 3
echo "== after =="; show
journalctl -k --since "-15s" --no-pager -o short-iso | grep -iE "hda|codec|azx" | sed -E 's/^[^ ]+ [^ ]+ kernel: //' | tail -5
