#!/bin/bash
# One-shot root setup for the laptop's audio quirks. Portable: re-run on a
# new machine.
#
#   sudo bash ~/.config/my/setup-audio.sh
#
# Why (2026-11-08): the laptop (TUXEDO InfinityBook Pro AMD Gen10) let out a
# loud high-pitched beep sequence right after a wake from lid-closed sleep.
# Nothing here needs the legacy PC speaker, and its square wave reaches the
# laptop speakers through the HDA codec's hardware "Beep" switch regardless
# of desktop volume. So:
#   1. Blacklist the pcspkr module (udev autoloads it from the PNP0800 id).
#   2. Unload it now.
#   3. Turn the codec's Beep volume to 0 (and switch off) on every sound
#      card that has one, then persist with alsactl store (alsa-restore
#      replays /var/lib/alsa/asound.state at boot). On this Conexant SN6140
#      the beep amp has no hardware mute (codec#0 node 0x12: mute=0), so the
#      switch is cosmetic and volume 0 only attenuates by 28 dB — step 1 is
#      the real fix; step 3 just makes any firmware-driven beep quieter.
#   4. Keep the HDA codec powered (power_save=0). Found 2026-11-09: the
#      Conexant SN6140 codec hung (zero nodes in /proc/asound/card1/codec#0,
#      "Power: UNKNOWN, Error", endless azx_single_wait_for_response
#      timeouts) and the speakers popped, then blared square-wave tones.
#      Codec D3/clock-stop transitions every 10 s idle are the usual trigger
#      for Conexant pops and lockups; a hung codec is reset with
#      hda-reset.sh (no reboot).
# If the machine still beeps after all this, the sound comes from the
# embedded controller's own buzzer and only the BIOS / TUXEDO support help.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

echo "== 1/4 blacklist pcspkr =="
printf 'blacklist pcspkr\n' > /etc/modprobe.d/nobeep.conf
cat /etc/modprobe.d/nobeep.conf

echo "== 2/4 unload pcspkr =="
if lsmod | grep -q '^pcspkr'; then modprobe -r pcspkr && echo unloaded; else echo "not loaded"; fi

echo "== 3/4 codec Beep off, persisted =="
for c in /proc/asound/card[0-9]*; do
  n=${c##*card}
  amixer -q -c "$n" sget Beep >/dev/null 2>&1 || continue
  amixer -q -c "$n" sset Beep 0% mute
  echo "card $n: $(amixer -c "$n" sget Beep | grep -o 'Playback [0-9]* .*')"
done
alsactl store && echo "stored /var/lib/alsa/asound.state"

echo "== 4/4 HDA codec power saving off =="
printf 'options snd_hda_intel power_save=0 power_save_controller=N\n' > /etc/modprobe.d/snd-hda-power-save.conf
echo 0 > /sys/module/snd_hda_intel/parameters/power_save
echo N > /sys/module/snd_hda_intel/parameters/power_save_controller
echo "power_save=$(cat /sys/module/snd_hda_intel/parameters/power_save) (persisted in /etc/modprobe.d/snd-hda-power-save.conf)"
