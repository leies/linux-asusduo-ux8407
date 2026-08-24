#!/bin/bash
# Permanently keep the UX8407 bottom OLED (eDP-2) off at the kernel too.
set -euo pipefail

if ((EUID != 0)); then
  echo "Re-running with sudo..."
  exec sudo -- "$0" "$@"
fi

cat >/etc/limine-entry-tool.d/asus-ux8407-display.conf <<'EOF'
# ASUS Zenbook Duo UX8407AA (Panther Lake / Xe3 iGPU)
KERNEL_CMDLINE[default]+=" xe.enable_dpcd_backlight=1"
KERNEL_CMDLINE[default]+=" xe.enable_psr=0 xe.enable_psr2_sel_fetch=0 xe.enable_panel_replay=0 xe.enable_dsb=0"
# Never light the bottom OLED: PHY B link training freezes the compositor.
KERNEL_CMDLINE[default]+=" video=eDP-2:d"
EOF

cat >/etc/modprobe.d/xe-asus-ux8407.conf <<'EOF'
options xe enable_dpcd_backlight=1 enable_psr=0 enable_psr2_sel_fetch=0 enable_panel_replay=0 enable_dsb=0
EOF

if [[ -x /home/triforce/.local/bin/omarchy-ux8407-keyboard ]]; then
  cp /home/triforce/.local/bin/omarchy-ux8407-keyboard /usr/local/bin/omarchy-ux8407-keyboard
  chmod 755 /usr/local/bin/omarchy-ux8407-keyboard
fi

echo "Updating Limine boot entries..."
limine-update
echo "Done."
