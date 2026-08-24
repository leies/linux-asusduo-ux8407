#!/bin/bash
# 1) Restore a clean UKI (remove the broken objcopy .acpi section).
# 2) Put the SSDT in mkinitcpio's *early* uncompressed cpio so
#    CONFIG_ACPI_TABLE_UPGRADE can load it.
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

AML_SRC=/home/triforce/.local/share/omarchy/ssdt-noswd0.aml
install -d /boot/acpi /etc/initcpio/install /etc/mkinitcpio.conf.d
install -m 644 "$AML_SRC" /boot/acpi/ssdt-noswd0.aml

cat >/etc/initcpio/install/acpi_override <<'EOF'
#!/bin/bash
build() {
  # Early (uncompressed) cpio — kernel ACPI table upgrade runs before the
  # compressed initramfs is unpacked.
  add_file_early /boot/acpi/ssdt-noswd0.aml /kernel/firmware/acpi/ssdt-noswd0.aml
}

help() {
  cat <<HELPEOF
Load SSDT that disables the UX8407 ghost RT722 (SWD0).
HELPEOF
}
EOF
chmod 755 /etc/initcpio/install/acpi_override

cat >/etc/mkinitcpio.conf.d/zz-ux8407-acpi.conf <<'EOF'
HOOKS+=(acpi_override)
EOF

# Do not leave a broken PE .acpi section on the UKI.
rm -f /usr/share/libalpm/hooks/zz-ux8407-uki-acpi.hook

echo "Rebuilding a clean UKI with early ACPI cpio..."
limine-update

echo
echo "Done. Reboot; dmesg should show OEM ID UX8407 / NOSWD0 and SWD0 should vanish."
