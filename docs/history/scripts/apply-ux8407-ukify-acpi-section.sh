#!/bin/bash
# Make mkinitcpio/ukify embed the SWD0 SSDT in the UKI .acpi PE section.
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

AML=/boot/acpi/ssdt-noswd0.aml
install -d /boot/acpi /usr/local/bin
install -m 644 /home/triforce/.local/share/omarchy/ssdt-noswd0.aml "$AML"
pacman -S --noconfirm --needed systemd-ukify

cat >/usr/local/bin/ukify <<EOF
#!/bin/bash
# Wrap systemd ukify to add the UX8407 ghost-RT722 SSDT as a .acpi section.
set -- "\$@"
if [[ \${1-} == build ]]; then
  exec /usr/bin/ukify "\$@" --section=.acpi:@${AML}
else
  exec /usr/bin/ukify "\$@"
fi
EOF
chmod 755 /usr/local/bin/ukify

# Drop the ignored ACPI= uki.conf key so it cannot confuse parsers.
rm -f /etc/kernel/uki.conf

echo "Rebuilding UKI..."
limine-update

echo
UKI=$(ls /boot/EFI/Linux/*.efi | head -1)
echo "UKI=$UKI"
objdump -h "$UKI" | grep -E 'acpi|\.linux|\.initrd' || objdump -h "$UKI"

echo
echo "Done. Reboot for the SSDT to hide SWD0."
