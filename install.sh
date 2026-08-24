#!/usr/bin/env bash
# Apply UX8407AA Phase 1 tweaks on Omarchy (Arch + Hyprland + Limine).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$REPO/files"
ORIG_ARGS=("$@")

SKIP_UKI=0
WINDOWS_ONLY=0
NO_FASTFETCH=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --windows-only   Only add/refresh the Windows 11 Limine entry
  --skip-uki       Install files but do not run limine-update
  --no-fastfetch   Do not append fastfetch to ~/.bashrc
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --windows-only) WINDOWS_ONLY=1 ;;
  --skip-uki) SKIP_UKI=1 ;;
  --no-fastfetch) NO_FASTFETCH=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1 && [[ -t 0 ]]; then
    exec sudo --preserve-env=SUDO_USER,SUDO_UID,SUDO_GID -- "$0" "${ORIG_ARGS[@]}"
  fi
  if command -v pkexec >/dev/null 2>&1; then
    exec pkexec env SUDO_USER="${SUDO_USER:-$USER}" SUDO_UID="$(id -u)" SUDO_GID="$(id -g)" \
      "$0" "${ORIG_ARGS[@]}"
  fi
  echo "Need root. Re-run with: sudo $0 ${ORIG_ARGS[*]}" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z $TARGET_USER || $TARGET_USER == root ]]; then
  TARGET_USER="$(logname 2>/dev/null || true)"
fi
if [[ -z $TARGET_USER || $TARGET_USER == root ]]; then
  TARGET_USER="$(awk -F: '$3==1000 {print $1; exit}' /etc/passwd)"
fi
if [[ -z $TARGET_USER ]]; then
  echo "Could not determine the desktop user." >&2
  exit 1
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GID="$(id -g "$TARGET_USER")"

stamp="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET_HOME/.local/share/linux-asusduo-ux8407/backup-$stamp"
mkdir -p "$BACKUP"
chown -R "$TARGET_UID:$TARGET_GID" "$(dirname "$BACKUP")" "$BACKUP"

backup_if_exists() {
  local src="$1" dest
  [[ -e $src ]] || return 0
  dest="$BACKUP$src"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
}

install_file() {
  local src="$1" dest="$2" mode="${3:-644}"
  backup_if_exists "$dest"
  install -d "$(dirname "$dest")"
  install -m "$mode" "$src" "$dest"
}

as_user() {
  local runtime="/run/user/$TARGET_UID"
  runuser -u "$TARGET_USER" -- env \
    XDG_RUNTIME_DIR="$runtime" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
    "$@"
}

install_windows_boot() {
  install_file "$FILES/etc/boot/hooks/post.d/80-windows-11-entry" \
    /etc/boot/hooks/post.d/80-windows-11-entry 755
  ESP_PATH="${ESP_PATH:-/boot}" bash /etc/boot/hooks/post.d/80-windows-11-entry
  if [[ -r ${ESP_PATH:-/boot}/limine.conf ]] && grep -q 'bootmgfw.efi' "${ESP_PATH:-/boot}/limine.conf"; then
    echo "Windows 11 is in Limine. Keep Limine first in the firmware boot order."
  else
    echo "Windows 11 entry was not added. Is a Windows ESP present?" >&2
  fi
}

if ((WINDOWS_ONLY)); then
  install_windows_boot
  echo "Done (Windows boot only). Reboot and pick Windows 11 in Limine."
  echo "Backups: $BACKUP"
  exit 0
fi

echo "Installing UX8407 Phase 1 as user $TARGET_USER ($TARGET_HOME)"

# ACPI SSDT (ghost RT722 / SWD0)
if command -v iasl >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  cp "$FILES/acpi/ssdt-noswd0.asl" "$tmp/"
  (cd "$tmp" && iasl -tc ssdt-noswd0.asl >/dev/null)
  AML="$tmp/ssdt-noswd0.aml"
else
  AML="$FILES/acpi/ssdt-noswd0.aml"
fi
install -d /boot/acpi
backup_if_exists /boot/acpi/ssdt-noswd0.aml
install -m 644 "$AML" /boot/acpi/ssdt-noswd0.aml
install -d "$TARGET_HOME/.local/share/omarchy"
install -m 644 "$FILES/acpi/ssdt-noswd0.asl" "$TARGET_HOME/.local/share/omarchy/ssdt-noswd0.asl"
install -m 644 "$AML" "$TARGET_HOME/.local/share/omarchy/ssdt-noswd0.aml"
echo 1 >"$TARGET_HOME/.local/share/omarchy/PHASE"
install -m 644 "$REPO/docs/PHASE1-STATUS.md" "$TARGET_HOME/.local/share/omarchy/PHASE1-STATUS.md"
chown -R "$TARGET_UID:$TARGET_GID" "$TARGET_HOME/.local/share/omarchy"

# Kernel / firmware / udev / initramfs
install_file "$FILES/etc/limine-entry-tool.d/asus-ux8407-display.conf" \
  /etc/limine-entry-tool.d/asus-ux8407-display.conf
install_file "$FILES/etc/modprobe.d/xe-asus-ux8407.conf" \
  /etc/modprobe.d/xe-asus-ux8407.conf
install_file "$FILES/etc/modprobe.d/iwlwifi-disable-eht.conf" \
  /etc/modprobe.d/iwlwifi-disable-eht.conf
install_file "$FILES/etc/udev/hwdb.d/90-ux8407-keyboard.hwdb" \
  /etc/udev/hwdb.d/90-ux8407-keyboard.hwdb
install_file "$FILES/etc/udev/rules.d/90-ux8407-keyboard.rules" \
  /etc/udev/rules.d/90-ux8407-keyboard.rules
install_file "$FILES/etc/udev/rules.d/99-asus-ux8407-screenpad.rules" \
  /etc/udev/rules.d/99-asus-ux8407-screenpad.rules
install_file "$FILES/etc/initcpio/install/acpi_override" \
  /etc/initcpio/install/acpi_override 755
install_file "$FILES/etc/initcpio/hooks/acpi_override" \
  /etc/initcpio/hooks/acpi_override 755
install_file "$FILES/etc/mkinitcpio.conf.d/zz-ux8407-acpi.conf" \
  /etc/mkinitcpio.conf.d/zz-ux8407-acpi.conf

# Keyboard helper: /usr/local/bin is visible before the encrypted home is unlocked
install_file "$FILES/usr/local/bin/omarchy-ux8407-keyboard" \
  /usr/local/bin/omarchy-ux8407-keyboard 755
install -d "$TARGET_HOME/.local/bin"
install -m 755 "$FILES/usr/local/bin/omarchy-ux8407-keyboard" \
  "$TARGET_HOME/.local/bin/omarchy-ux8407-keyboard"
chown "$TARGET_UID:$TARGET_GID" "$TARGET_HOME/.local/bin/omarchy-ux8407-keyboard"

# Hyprland + user service
install -d "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/systemd/user" \
  "$TARGET_HOME/.local/state/omarchy/toggles/hypr"
install_file "$FILES/home/config/hypr/monitors.lua" "$TARGET_HOME/.config/hypr/monitors.lua"
install_file "$FILES/home/config/hypr/bindings.lua" "$TARGET_HOME/.config/hypr/bindings.lua"
install_file "$FILES/home/config/systemd/user/omarchy-ux8407-keyboard.service" \
  "$TARGET_HOME/.config/systemd/user/omarchy-ux8407-keyboard.service"
install_file "$FILES/home/local/state/omarchy/toggles/hypr/ux8407-bottom-screen.lua" \
  "$TARGET_HOME/.local/state/omarchy/toggles/hypr/ux8407-bottom-screen.lua"
chown -R "$TARGET_UID:$TARGET_GID" \
  "$TARGET_HOME/.config/hypr/monitors.lua" \
  "$TARGET_HOME/.config/hypr/bindings.lua" \
  "$TARGET_HOME/.config/systemd/user/omarchy-ux8407-keyboard.service" \
  "$TARGET_HOME/.local/state/omarchy"

if ((NO_FASTFETCH == 0)) && [[ -f $TARGET_HOME/.bashrc ]]; then
  if ! grep -q 'command -v fastfetch' "$TARGET_HOME/.bashrc"; then
    backup_if_exists "$TARGET_HOME/.bashrc"
    printf '\n' >>"$TARGET_HOME/.bashrc"
    cat "$FILES/home/bashrc.fastfetch" >>"$TARGET_HOME/.bashrc"
    chown "$TARGET_UID:$TARGET_GID" "$TARGET_HOME/.bashrc"
  fi
fi

systemd-hwdb update
udevadm control --reload
udevadm trigger --subsystem-match=hidraw --subsystem-match=input --subsystem-match=backlight || true

as_user systemctl --user daemon-reload
as_user systemctl --user enable --now omarchy-ux8407-keyboard.service
as_user systemctl --user disable --now omarchy-ux8407-dock-watch.service 2>/dev/null || true

if command -v hyprctl >/dev/null 2>&1; then
  as_user hyprctl reload >/dev/null 2>&1 || true
fi

install_windows_boot

if ((SKIP_UKI == 0)); then
  echo "Rebuilding UKI / Limine entries (acpi_override + display cmdline)..."
  limine-update
  # limine-update rewrites limine.conf; re-apply Windows after that.
  ESP_PATH="${ESP_PATH:-/boot}" bash /etc/boot/hooks/post.d/80-windows-11-entry
fi

echo
echo "Phase 1 installed."
echo "  Bottom OLED (eDP-2) stays off — do not re-enable it."
echo "  Firmware boot order should list Limine first; Windows 11 is in that menu."
echo "  Reboot once so the early ACPI SSDT and Xe options take effect."
echo "  Backups: $BACKUP"
