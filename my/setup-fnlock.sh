#!/bin/bash
# One-shot root setup: keep the laptop's Fn lock ON so the F-row types
# F1-F12 without holding Fn. Portable: re-run on a new machine.
#
#   sudo bash ~/.config/my/setup-fnlock.sh        # fn_lock=1 (default)
#   sudo bash ~/.config/my/setup-fnlock.sh 0      # if the EC's sense is inverted
#
# Why (2026-11-27): the TUXEDO InfinityBook Pro AMD Gen10's embedded
# controller forgets Fn lock. A BIOS update reset it on 2026-11-11 and
# `echo 1 > fn_lock` fixed it by hand, but by 2026-11-27 it read 0 again
# with no reboot or hibernate in between — only 42 s2idle suspend/resume
# cycles — so the setting dies across sleep (or an accidental Fn+Esc) and
# the tuxedo_keyboard driver restores nothing. This installs a oneshot
# service that writes the value at boot (waiting for the module to show up)
# and again after every resume (suspend, hibernate, hybrid, suspend-then-
# hibernate), and applies it right now.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
VALUE="${1:-1}"
ATTR=/sys/devices/platform/tuxedo_keyboard/fn_lock

echo "== 1/3 helper /usr/local/bin/tuxedo-fn-lock =="
cat > /usr/local/bin/tuxedo-fn-lock <<HELPER
#!/bin/sh
# Installed by ~/.config/my/setup-fnlock.sh. Waits up to 30 s for the
# tuxedo_keyboard platform device, then sets Fn lock.
for _ in \$(seq 1 30); do
    if [ -w $ATTR ]; then
        echo $VALUE > $ATTR && exit 0
    fi
    sleep 1
done
echo "tuxedo-fn-lock: $ATTR never appeared" >&2
exit 1
HELPER
chmod 755 /usr/local/bin/tuxedo-fn-lock
cat /usr/local/bin/tuxedo-fn-lock

echo "== 2/3 unit tuxedo-fn-lock.service (boot + after every resume) =="
cat > /etc/systemd/system/tuxedo-fn-lock.service <<'UNIT'
[Unit]
Description=TUXEDO Fn lock (F-row = F1-F12 without holding Fn)
# Boot: run once the keyboard module is likely up (the helper also waits).
After=systemd-modules-load.service
# Resume: a unit ordered After= a sleep target and wanted by it starts when
# the target is reached, i.e. right after the machine wakes.
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tuxedo-fn-lock

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
UNIT
systemctl daemon-reload
systemctl enable tuxedo-fn-lock.service

echo "== 3/3 apply now =="
systemctl restart tuxedo-fn-lock.service
echo "fn_lock = $(cat $ATTR)  (wanted $VALUE)"
