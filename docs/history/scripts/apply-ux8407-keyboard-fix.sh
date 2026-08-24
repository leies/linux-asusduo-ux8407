#!/bin/bash
# System-level UX8407AA function-key fix: udev hwdb remap + hidraw access.
set -euo pipefail

if ((EUID != 0)); then
  echo "Re-running with sudo..."
  exec sudo -- "$0" "$@"
fi

product=$(tr -d '\0' </sys/class/dmi/id/product_name 2>/dev/null || true)
if [[ $product != *UX8407* ]]; then
  echo "This script is for ASUS Zenbook Duo UX8407 (found: ${product:-unknown})" >&2
  exit 1
fi

mkdir -p /etc/udev/hwdb.d /etc/udev/rules.d

cat >/etc/udev/hwdb.d/90-ux8407-keyboard.hwdb <<'EOF'
# ASUS Zenbook Duo UX8407AA Primax keyboard (USB 0b05:1cd7)
# Map F1–F6 scancodes to the printed hotkeys when firmware is in F-key mode.
evdev:input:b0003v0B05p1CD7*
 KEYBOARD_KEY_7003a=mute
 KEYBOARD_KEY_7003b=volumedown
 KEYBOARD_KEY_7003c=volumeup
 KEYBOARD_KEY_7003d=kbdillumtoggle
 KEYBOARD_KEY_7003e=brightnessdown
 KEYBOARD_KEY_7003f=brightnessup
EOF

cat >/etc/udev/rules.d/90-ux8407-keyboard.rules <<'EOF'
# Detachable Duo keyboard HID: allow the session to set Fn-lock / backlight.
KERNEL=="hidraw*", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1cd7", GROUP="input", MODE="0660", TAG+="uaccess"
ACTION=="add", KERNEL=="hidraw*", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1cd7", RUN+="/home/triforce/.local/bin/omarchy-ux8407-keyboard init"
EOF

systemd-hwdb update
udevadm control --reload
udevadm trigger -s input
udevadm trigger -s hidraw

echo
echo "Wrote:"
echo "  /etc/udev/hwdb.d/90-ux8407-keyboard.hwdb"
echo "  /etc/udev/rules.d/90-ux8407-keyboard.rules"
echo
echo "Done. Function keys should match the printed UX8407 layout."
echo "Hold Fn for the real F1–F12 after Fn-lock init succeeds."
