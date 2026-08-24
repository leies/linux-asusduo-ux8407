#!/bin/bash
# Hide the ghost RT722 SoundWire device (SWD0) so sof_sdw can register.
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

AML_SRC=/home/triforce/.local/share/omarchy/ssdt-noswd0.aml
install -d /boot/acpi /etc/initcpio/install /etc/initcpio/hooks /etc/mkinitcpio.conf.d
install -m 644 "$AML_SRC" /boot/acpi/ssdt-noswd0.aml

cat >/etc/initcpio/install/acpi_override <<'EOF'
#!/bin/bash
build() {
  add_file /boot/acpi/ssdt-noswd0.aml /kernel/firmware/acpi/ssdt-noswd0.aml
}

help() {
  cat <<HELPEOF
Load a custom SSDT that disables the UX8407 ghost RT722 (SWD0).
HELPEOF
}
EOF
chmod 755 /etc/initcpio/install/acpi_override

# hooks/ file can be empty for install-only hooks
cat >/etc/initcpio/hooks/acpi_override <<'EOF'
# no runtime hook; table is loaded from initramfs by the kernel
EOF
chmod 755 /etc/initcpio/hooks/acpi_override

cat >/etc/mkinitcpio.conf.d/zz-ux8407-acpi.conf <<'EOF'
HOOKS+=(acpi_override)
EOF

# Revert the SOF topology workaround; function topologies work once SWD0 is gone.
rm -f /etc/modprobe.d/ux8407-audio.conf
rm -f /etc/limine-entry-tool.d/asus-ux8407-audio.conf

echo "Rebuilding UKI/initramfs..."
limine-update

echo
echo "Done. Reboot for the ACPI override to hide SWD0/RT722."
