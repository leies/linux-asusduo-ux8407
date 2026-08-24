#!/bin/bash
# System-level display fix for ASUS Zenbook Duo UX8407AA on Intel Xe / Panther Lake.
# Requires root. Writes Limine cmdline, xe module options, and hides the
# bogus ScreenPad backlight that systemd-backlight fails to restore.

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

mkdir -p /etc/limine-entry-tool.d /etc/modprobe.d /etc/udev/rules.d

cat >/etc/limine-entry-tool.d/asus-ux8407-display.conf <<'EOF'
# ASUS Zenbook Duo UX8407AA (Panther Lake / Xe3 iGPU)
#
# Brightness: VBT claims PWM, but the dual OLEDs need DPCD AUX backlight.
# Without this, intel_backlight writes succeed and do nothing visible.
#
# Boot freeze: PSR / Panel Replay wedges pipe B. Symptoms are wallpaper +
# hardware cursor with a frozen compositor, and kernel logs:
#   Timed out waiting PSR idle state
#   flip_done timed out
#   [CRTC:pipe B] commit wait timed out
KERNEL_CMDLINE[default]+=" xe.enable_dpcd_backlight=1 xe.enable_psr=0 xe.enable_psr2_sel_fetch=0 xe.enable_panel_replay=0"
EOF

cat >/etc/modprobe.d/xe-asus-ux8407.conf <<'EOF'
# Same flags as the Limine cmdline, in case xe loads as a module.
options xe enable_dpcd_backlight=1 enable_psr=0 enable_psr2_sel_fetch=0 enable_panel_replay=0
EOF

cat >/etc/udev/rules.d/99-asus-ux8407-screenpad.rules <<'EOF'
# UX8407 has two full eDP panels, not a ScreenPad. asus-nb-wmi still exports
# a broken asus_screenpad backlight (overflowed brightness, systemd restore fails).
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="asus_screenpad", ENV{SYSTEMD_WANTS}=""
EOF

if ! systemctl is-enabled systemd-backlight@backlight:asus_screenpad.service >/dev/null 2>&1; then
  :
fi
systemctl mask systemd-backlight@backlight:asus_screenpad.service

echo
echo "Wrote:"
echo "  /etc/limine-entry-tool.d/asus-ux8407-display.conf"
echo "  /etc/modprobe.d/xe-asus-ux8407.conf"
echo "  /etc/udev/rules.d/99-asus-ux8407-screenpad.rules"
echo
echo "Updating Limine boot entries (rebuilds UKI/initramfs)..."
limine-update

echo
echo "Done. Reboot for brightness and the boot-freeze fix to take effect."
echo "After reboot, Fn brightness keys should drive both OLED panels."
