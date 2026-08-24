#!/bin/bash
if ((EUID != 0)); then exec sudo -- "$0" "$@"; fi
objdump -h /boot/EFI/Linux/omarchy_linux.efi | tee /tmp/uki-sections.txt
chmod a+r /tmp/uki-sections.txt
