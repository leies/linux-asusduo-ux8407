#!/bin/bash
# Un-blacklist ghost RT722 so sof_sdw can finish probe, keep forced topology.
set -euo pipefail

if ((EUID != 0)); then
  exec sudo -- "$0" "$@"
fi

cat >/etc/modprobe.d/ux8407-audio.conf <<'EOF'
# Keep function topologies off; load the PTL cs42l43+cs35l56 topology.
# Do not blacklist rt722: sof_sdw waits for every ACPI SDW device to bind.
options snd_sof disable_function_topology=1
options snd_sof tplg_filename="sof-ptl-cs42l43-agg-l3-cs35l56-l2.tplg"
EOF

modprobe snd_soc_rt722_sdca || true
sleep 1

# Retry sof_sdw bind now that codecs are present.
if [[ ! -e /sys/bus/platform/drivers/sof_sdw/sof_sdw ]]; then
  echo -n sof_sdw >/sys/bus/platform/drivers/sof_sdw/bind || true
fi
sleep 2

echo "=== cards ==="
cat /proc/asound/cards || true
echo
echo "=== last sof lines ==="
journalctl -k --since '30 sec ago' --no-pager | grep -iE 'sof_sdw|tplg|widget|instantiate|error|SimpleJack|SmartAmp' | tail -40
echo
echo "=== sdw drivers ==="
for d in /sys/bus/soundwire/devices/sdw:*; do
  printf '%s driver=%s\n' "$(basename "$d")" "$(basename "$(readlink "$d/driver" 2>/dev/null || echo NONE)")"
done
