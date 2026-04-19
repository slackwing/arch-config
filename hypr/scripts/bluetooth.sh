#!/usr/bin/env bash
DEVICE_MAC="EB:06:EF:99:A6:E0"
DEVICE_NAME="Esinkin BT Adapter"

is_connected() {
    bluetoothctl info "$DEVICE_MAC" 2>/dev/null | grep -q "Connected: yes"
}

if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
    notify-send "Bluetooth" "Powered off"
else
    rfkill unblock bluetooth
    bluetoothctl power on
    sleep 2

    # Retry up to 3 times
    for i in {1..3}; do
        bluetoothctl connect "$DEVICE_MAC" >/dev/null 2>&1
        sleep 1
        if is_connected; then
            notify-send "Bluetooth" "Connected to $DEVICE_NAME"
            exit 0
        fi
        sleep 1
    done

    notify-send -u critical "Bluetooth" "Failed to connect to $DEVICE_NAME after 5 attempts"
fi
