#!/bin/bash
# Stamp the ghost-RT722 SSDT into the UKI as a .acpi PE section.
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

AML=/boot/acpi/ssdt-noswd0.aml
install -d /boot/acpi
install -m 644 /home/triforce/.local/share/omarchy/ssdt-noswd0.aml "$AML"

stamp_uki() {
  local uki="$1"
  [[ -f $uki ]] || return 0
  if objdump -h "$uki" | grep -q '\.acpi'; then
    echo "$uki already has .acpi"
    return 0
  fi
  local tmp
  tmp=$(mktemp "${uki}.XXXXXX")
  if objcopy --add-section .acpi="$AML" \
    --set-section-flags .acpi=contents,alloc,load,readonly,data \
    "$uki" "$tmp"; then
    mv -f "$tmp" "$uki"
    echo "Stamped .acpi onto $uki"
  else
    rm -f "$tmp"
    echo "objcopy failed for $uki" >&2
    return 1
  fi
}

# Also re-stamp after every limine UKI rebuild.
install -d /usr/share/libalpm/hooks /usr/local/lib/omarchy
cat >/usr/local/lib/omarchy/stamp-uki-acpi.sh <<'EOF'
#!/bin/bash
AML=/boot/acpi/ssdt-noswd0.aml
[[ -f $AML ]] || exit 0
for uki in /boot/EFI/Linux/*.efi; do
  [[ -f $uki ]] || continue
  objdump -h "$uki" | grep -q '\.acpi' && continue
  tmp=$(mktemp "${uki}.XXXXXX")
  if objcopy --add-section .acpi="$AML" \
    --set-section-flags .acpi=contents,alloc,load,readonly,data \
    "$uki" "$tmp"; then
    mv -f "$tmp" "$uki"
  else
    rm -f "$tmp"
  fi
done
EOF
chmod 755 /usr/local/lib/omarchy/stamp-uki-acpi.sh

cat >/usr/share/libalpm/hooks/zz-ux8407-uki-acpi.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = linux-ptl
Target = limine-mkinitcpio-hook

[Action]
Description = Stamp UX8407 SSDT into UKI .acpi section
When = PostTransaction
Exec = /usr/local/lib/omarchy/stamp-uki-acpi.sh
EOF

shopt -s nullglob
for uki in /boot/EFI/Linux/*.efi; do
  stamp_uki "$uki"
done

echo
echo "=== sections ==="
objdump -h /boot/EFI/Linux/omarchy_linux.efi | grep -E 'acpi|\.linux|\.initrd'
echo
echo "Done. Reboot."
