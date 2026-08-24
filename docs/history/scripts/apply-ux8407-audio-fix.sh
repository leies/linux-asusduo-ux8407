#!/bin/bash
# UX8407AA: ACPI advertises a ghost RT722 on SoundWire link 3 next to the
# real CS42L43. Function topologies then create two SDW3-Playback-SimpleJack
# DAIs and sof_sdw fails with -ENOMEM. Same class of bug as UX5406AA.
set -euo pipefail

if ((EUID != 0)); then
  echo "Re-running with sudo..."
  exec sudo -- "$0" "$@"
fi

mkdir -p /etc/modprobe.d /etc/limine-entry-tool.d

cat >/etc/modprobe.d/ux8407-audio.conf <<'EOF'
# Ghost Realtek RT722 in ACPI (not present on the board).
blacklist snd_soc_rt722_sdca

# Do not build the card from the ACPI function list (includes the ghost).
options snd_sof disable_function_topology=1
options snd_sof tplg_filename="sof-ptl-cs42l43-agg-l3-cs35l56-l2.tplg"
EOF

# Also bake into the UKI cmdline so params apply even if sof is built-in.
dropin=/etc/limine-entry-tool.d/asus-ux8407-audio.conf
cat >"$dropin" <<'EOF'
# UX8407AA SOF: skip ghost RT722 function-topology path
KERNEL_CMDLINE[default]+=" snd_sof.disable_function_topology=1 snd_sof.tplg_filename=sof-ptl-cs42l43-agg-l3-cs35l56-l2.tplg"
EOF

# Stop userspace so modules can unload.
systemctl --user --machine=triforce@ stop pipewire.socket pipewire.service pipewire-pulse.socket pipewire-pulse.service wireplumber.service 2>/dev/null || true
sleep 1

# Drop the SOF PCI driver, unload the ghost codec, reload with new params.
if [[ -e /sys/bus/pci/drivers/sof-audio-pci-intel-ptl/0000:00:1f.3 ]]; then
  echo -n 0000:00:1f.3 >/sys/bus/pci/drivers/sof-audio-pci-intel-ptl/unbind || true
fi
sleep 1
modprobe -r snd_soc_sof_sdw 2>/dev/null || true
modprobe -r snd_soc_rt722_sdca 2>/dev/null || true
# Reload snd_sof so disable_function_topology / tplg_filename take effect.
if ! lsmod | grep -q '^snd_sof '; then
  modprobe snd_sof disable_function_topology=1 tplg_filename=sof-ptl-cs42l43-agg-l3-cs35l56-l2.tplg
fi

if [[ -e /sys/bus/pci/devices/0000:00:1f.3 ]]; then
  echo -n 0000:00:1f.3 >/sys/bus/pci/drivers/sof-audio-pci-intel-ptl/bind || \
    echo 1 >/sys/bus/pci/rescan || true
fi

sleep 2
echo
echo "=== /proc/asound/cards ==="
cat /proc/asound/cards || true
echo
echo "Updating Limine so the SOF params survive reboot..."
limine-update

echo
echo "Done. If no card is listed above, reboot once."
