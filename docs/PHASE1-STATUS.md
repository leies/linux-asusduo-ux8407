# Phase 1 — UX8407AA Omarchy (working baseline)

Marked: 2026-08-23  
Machine: ASUS Zenbook Duo UX8407AA  
OS: Omarchy 4.0.0-1, kernel 7.1.8-arch1-3

This is the known-good laptop setup after the first round of hardware fixes.
Do not treat later experiments as Phase 1 unless this file is updated.

## Working

| Area | State |
|------|--------|
| Boot / GUI | Top OLED only; no long freeze at login |
| Brightness | Fn / F5–F6 control both intended paths via `intel_backlight` + DPCD |
| Speakers | `sof-soundwire` card present; default sink is Speaker |
| Microphone | Default source is HD Audio Microphones; mute works |
| Keyboard F-row | Custom Hyprland map (see below) |
| Keyboard backlight | HID cycle on F4 |

## Sleep / lid

s2idle hangs after `PM: suspend entry (s2idle)`; lid open and power button do not wake. Use S3 (`MemorySleepMode=deep`).

## Intentionally off

- **Bottom OLED (`eDP-2`) never turns on.** Kernel `video=eDP-2:d` plus Hyprland `disabled = true`. Enabling it wedges Intel PHY B and freezes the compositor.

## Kernel cmdline (display)

From `/etc/limine-entry-tool.d/asus-ux8407-display.conf`:

- `xe.enable_dpcd_backlight=1`
- `xe.enable_psr=0`
- `xe.enable_psr2_sel_fetch=0`
- `xe.enable_panel_replay=0`
- `xe.enable_dsb=0`
- `video=eDP-2:d`

## Audio

Ghost Realtek RT722 (`SWD0`, ACPI `_SB.PC00.HDAS.IDA.SNDW.SWD0`) is hidden with SSDT `ssdt-noswd0.aml` in the **early** initramfs (`add_file_early` via hook `acpi_override`). Real hardware is CS42L43 + 2× CS35L56.

ALSA card: `sofsoundwire` (`ASUSTeKCOMPUTERINC.-ZenbookDuoUX8407AA`).

## F-row (Phase 1)

| Key | Action |
|-----|--------|
| F1 | Speaker mute |
| F2 | Volume down |
| F3 | Volume up |
| F4 | Keyboard backlight cycle |
| F5 | Display brightness down |
| F6 | Display brightness up |
| F8 | Screenshot |
| F9 | Toggle touchpad |
| F10 | **Microphone mute** |
| F12 | Display / hardware menu |

Hold Fn for real F1–F12 after keyboard HID init. Super+Ctrl+X still toggles dictation (F9 was voxtype PTT).

## Config files to keep

User:

- `~/.config/hypr/monitors.lua` — eDP-1 2880x1800@144, scale 1.6, transform 2; eDP-2 disabled
- `~/.config/hypr/bindings.lua` — F-row map above
- `~/.local/bin/omarchy-ux8407-keyboard` — Fn-lock, HID backlight
- `~/.local/share/omarchy/ssdt-noswd0.asl` / `ssdt-noswd0.aml`

System (root):

- `/etc/limine-entry-tool.d/asus-ux8407-display.conf`
- `/etc/modprobe.d/xe-asus-ux8407.conf`
- `/etc/udev/hwdb.d/90-ux8407-keyboard.hwdb`
- `/etc/udev/rules.d/90-ux8407-keyboard.rules`
- `/etc/initcpio/install/acpi_override`
- `/etc/mkinitcpio.conf.d/zz-ux8407-acpi.conf`
- `/boot/acpi/ssdt-noswd0.aml`
- `/usr/local/bin/omarchy-ux8407-keyboard` (udev at boot cannot see encrypted home)

## After kernel / Omarchy updates

1. `limine-update` must still pick up the display drop-in.
2. Rebuild UKI so the early ACPI SSDT stays in initramfs (`acpi_override` hook).
3. Do not re-enable eDP-2 unless a later kernel actually trains PHY B.
