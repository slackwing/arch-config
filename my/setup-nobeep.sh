#!/bin/bash
# One-shot root setup: silence the PC-speaker beep path. Portable: re-run on
# a new machine.
#
#   sudo bash ~/.config/my/setup-nobeep.sh
#
# Why (2026-11-08): the laptop (TUXEDO InfinityBook Pro AMD Gen10) let out a
# loud high-pitched beep sequence right after a wake from lid-closed sleep.
# Nothing here needs the legacy PC speaker, and its square wave reaches the
# laptop speakers through the HDA codec's hardware "Beep" switch regardless
# of desktop volume. So:
#   1. Blacklist the pcspkr module (udev autoloads it from the PNP0800 id).
#   2. Unload it now.
#   3. Turn the codec's Beep switch off and its volume to 0 on every sound
#      card that has one, then persist with alsactl store (alsa-restore
#      replays /var/lib/alsa/asound.state at boot).
# If the machine still beeps after this, the sound comes from the embedded
# controller's own buzzer and only the BIOS setup / TUXEDO support can help.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

echo "== 1/3 blacklist pcspkr =="
printf 'blacklist pcspkr\n' > /etc/modprobe.d/nobeep.conf
cat /etc/modprobe.d/nobeep.conf

echo "== 2/3 unload pcspkr =="
if lsmod | grep -q '^pcspkr'; then modprobe -r pcspkr && echo unloaded; else echo "not loaded"; fi

echo "== 3/3 codec Beep off, persisted =="
for c in /proc/asound/card[0-9]*; do
  n=${c##*card}
  amixer -q -c "$n" sget Beep >/dev/null 2>&1 || continue
  amixer -q -c "$n" sset Beep 0% mute
  echo "card $n: $(amixer -c "$n" sget Beep | grep -o 'Playback [0-9]* .*')"
done
alsactl store && echo "stored /var/lib/alsa/asound.state"
