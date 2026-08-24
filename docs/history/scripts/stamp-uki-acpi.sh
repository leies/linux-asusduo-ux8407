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
