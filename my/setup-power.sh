#!/bin/bash
# One-shot root setup for laptop power management. Portable: re-run on a new
# machine (it re-derives offsets; review the DEVICE-SPECIFIC bits first).
# Companion user-side config: hypr/hypridle.conf + exec-once in hyprland.conf.
#
#   sudo bash ~/.config/my/setup-power.sh
#
# What it does and why (diagnosed 2026-07: machine woke from lid-closed
# suspend ~94 times in one night — Logitech receiver wake + shallow s2idle
# sleep — and drained to dead):
#   1. Forbid the Logitech USB receiver from waking the machine.
#   2. Replace the 8G swap partition with a 40G /swapfile so hibernation
#      (image = in-use RAM, compressed) reliably fits on a 124G-RAM machine.
#   3. Point kernel resume at the swapfile (GRUB cmdline).
#   4. Lid close => suspend-then-hibernate. HibernateDelaySec is left UNSET
#      on purpose: systemd (253+) then samples the battery during sleep and
#      hibernates only when it estimates the battery is nearly empty — so the
#      machine sleeps indefinitely while the battery holds, and a closed lid
#      still can never drain to dead.
#   5. UPower: hibernate at 5% battery (lid-open case).
#   6. Install hypridle (screen off 10 min idle, suspend 30 min idle).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

# --- DEVICE-SPECIFIC (this machine, 2026-07) ---
OLD_SWAP_PART=/dev/nvme0n1p3
OLD_SWAP_UUID=6ad7e851-ac16-4abc-a500-36f89a4cc316
ROOT_UUID=635cc85c-a521-4f60-92f5-f6c33b00b523
SWAPFILE_MB=40960

echo "== 1/6 hypridle =="
pacman -S --needed --noconfirm hypridle || {
    echo "hypridle install failed — if mirrors 404'd, the package db is stale:" >&2
    echo "run a full 'pacman -Syu' (the 'upgrade' alias), then rerun this script." >&2
    exit 1
}

echo "== 2/6 udev: Logitech receiver cannot wake from suspend =="
cat > /etc/udev/rules.d/90-logitech-no-wakeup.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", ATTR{power/wakeup}="disabled"
EOF
udevadm control --reload
# Apply immediately to the already-plugged receiver too.
for d in /sys/bus/usb/devices/*/idVendor; do
    if [[ $(cat "$d") == 046d ]]; then
        echo disabled > "$(dirname "$d")/power/wakeup" 2>/dev/null || true
    fi
done

echo "== 3/6 swapfile (${SWAPFILE_MB}M) replacing ${OLD_SWAP_PART} =="
if [[ ! -f /swapfile ]]; then
    dd if=/dev/zero of=/swapfile bs=1M count="$SWAPFILE_MB" status=progress
    chmod 600 /swapfile
    mkswap /swapfile
fi
swapon /swapfile 2>/dev/null || true
swapoff "$OLD_SWAP_PART" 2>/dev/null || true
sed -i "s|^UUID=${OLD_SWAP_UUID}.*|/swapfile\tnone\tswap\tdefaults\t0 0|" /etc/fstab

echo "== 4/6 GRUB: resume from swapfile =="
OFFSET=$(filefrag -v /swapfile | awk '$1=="0:" {gsub(/\.\./,"",$4); print $4; exit}')
[[ -n $OFFSET ]] || { echo "could not determine resume_offset" >&2; exit 1; }
sed -i "s|resume=UUID=${OLD_SWAP_UUID}|resume=UUID=${ROOT_UUID} resume_offset=${OFFSET}|" /etc/default/grub
grep -q "resume_offset=${OFFSET}" /etc/default/grub || { echo "grub cmdline edit failed" >&2; exit 1; }
grub-mkconfig -o /boot/grub/grub.cfg

echo "== 5/6 logind: lid => suspend-then-hibernate (hibernate on low battery) =="
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/50-lid.conf <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
EOF
# Power key: never poweroff on a tap (logind's default!). Wake-from-suspend
# is firmware-level and unaffected. Long-press (5s) = graceful shutdown.
cat > /etc/systemd/logind.conf.d/50-power-key.conf <<'EOF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
EOF
# No HibernateDelaySec drop-in: unset means hibernate-on-battery-estimate.
rm -f /etc/systemd/sleep.conf.d/50-hibernate.conf
# NOTE: do NOT `systemctl restart systemd-logind` here — it tears down the
# running Wayland session (kills Hyprland). The config applies on reboot,
# which the GRUB resume change requires anyway.

echo "== 6/6 UPower: hibernate at 5% battery =="
sed -i -e 's/^PercentageCritical=.*/PercentageCritical=8.0/' \
       -e 's/^PercentageAction=.*/PercentageAction=5.0/' \
       -e 's/^CriticalPowerAction=.*/CriticalPowerAction=Hibernate/' \
       /etc/UPower/UPower.conf
systemctl restart upower

echo
echo "== verify =="
swapon --show
grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub
cat /sys/bus/usb/devices/3-2/power/wakeup 2>/dev/null || true
echo
echo "Done. Start hypridle now with: hypridle & disown  (auto-starts next login)"
echo "When convenient, test hibernation once: systemctl hibernate"
