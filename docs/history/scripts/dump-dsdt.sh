#!/bin/bash
set -euo pipefail
if ((EUID != 0)); then exec sudo -- "$0" "$@"; fi
mkdir -p /tmp/acpi-ux8407
cat /sys/firmware/acpi/tables/DSDT >/tmp/acpi-ux8407/DSDT.dat
if command -v iasl >/dev/null; then
  iasl -d /tmp/acpi-ux8407/DSDT.dat >/tmp/acpi-ux8407/iasl.log 2>&1 || true
else
  pacman -S --noconfirm acpica
  iasl -d /tmp/acpi-ux8407/DSDT.dat >/tmp/acpi-ux8407/iasl.log 2>&1 || true
fi
chmod -R a+rX /tmp/acpi-ux8407
echo "dumped to /tmp/acpi-ux8407"
