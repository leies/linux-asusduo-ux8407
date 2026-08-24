#!/bin/bash
if ((EUID != 0)); then exec sudo -- "$0" "$@"; fi
UKI=$(ls /boot/EFI/Linux/*.efi | head -1)
echo "UKI=$UKI"
objdump -h "$UKI"
echo
ukify inspect "$UKI" 2>/dev/null | head -40 || true
