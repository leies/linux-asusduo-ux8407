#!/bin/bash
# Embed the SWD0-disable SSDT in the UKI .acpi section (initramfs is too late).
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

AML=/boot/acpi/ssdt-noswd0.aml
install -d /boot/acpi /etc/kernel
install -m 644 /home/triforce/.local/share/omarchy/ssdt-noswd0.aml "$AML"

pacman -S --noconfirm --needed systemd-ukify

# systemd 261 ukify: ACPI= in [UKI] maps to --acpi-table=
cat >/etc/kernel/uki.conf <<EOF
[UKI]
ACPI=$AML
EOF

# Show what ukify accepts
ukify --help 2>&1 | grep -i acpi || true

echo "Rebuilding UKI with ACPI overlay..."
limine-update

echo
echo "=== UKI sections (looking for .acpi) ==="
UKI=$(ls /boot/EFI/Linux/*.efi 2>/dev/null | head -1 || true)
if [[ -n $UKI ]]; then
  objdump -h "$UKI" | grep -E 'acpi|Idx|Name' || objdump -h "$UKI" | head -40
fi

echo
echo "Done. Reboot required."
