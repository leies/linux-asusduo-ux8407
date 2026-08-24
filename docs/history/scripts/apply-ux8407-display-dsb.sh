#!/bin/bash
# Add xe.enable_dsb=0 to the UX8407 display cmdline (pipe B DSB timeouts).
set -euo pipefail

if ((EUID != 0)); then
  echo "Re-running with sudo..."
  exec sudo -- "$0" "$@"
fi

dropin=/etc/limine-entry-tool.d/asus-ux8407-display.conf
mkdir -p /etc/limine-entry-tool.d /usr/local/bin

cat >"$dropin" <<'EOF'
# ASUS Zenbook Duo UX8407AA (Panther Lake / Xe3 iGPU)
#
# Brightness: VBT claims PWM, but the dual OLEDs need DPCD AUX backlight.
KERNEL_CMDLINE[default]+=" xe.enable_dpcd_backlight=1"
#
# Boot freeze: PSR / Panel Replay / DSB wedge pipe B (eDP-2 / PHY B).
KERNEL_CMDLINE[default]+=" xe.enable_psr=0 xe.enable_psr2_sel_fetch=0 xe.enable_panel_replay=0 xe.enable_dsb=0"
EOF

cat >/etc/modprobe.d/xe-asus-ux8407.conf <<'EOF'
options xe enable_dpcd_backlight=1 enable_psr=0 enable_psr2_sel_fetch=0 enable_panel_replay=0 enable_dsb=0
EOF

# udev at boot cannot see an encrypted home; keep a copy on the root fs.
if [[ -x /home/triforce/.local/bin/omarchy-ux8407-keyboard ]]; then
  cp /home/triforce/.local/bin/omarchy-ux8407-keyboard /usr/local/bin/omarchy-ux8407-keyboard
  chmod 755 /usr/local/bin/omarchy-ux8407-keyboard
fi

if [[ -f /etc/udev/rules.d/90-ux8407-keyboard.rules ]]; then
  sed -i 's|/home/triforce/.local/bin/omarchy-ux8407-keyboard|/usr/local/bin/omarchy-ux8407-keyboard|g' \
    /etc/udev/rules.d/90-ux8407-keyboard.rules
  udevadm control --reload
fi

echo "Updating Limine boot entries..."
limine-update

echo
echo "Done. Reboot so xe.enable_dsb=0 takes effect."
echo "This login also keeps eDP-2 off until the keyboard is undocked (or F7)."
