# linux-asusduo-ux8407

Hi all, this is Leies, I make this repo for Omarchy from **ASUS Zenbook Duo UX8407AA** (2026, Intel Panther Lake) on [Omarchy](https://omarchy.org/) (Arch + Hyprland + Limine UKI).

Since i can't found any workground for Linux, so this is the known-good setup after the first hardware-fix round: TOP OLED only, Keyboard MUST attached (didnt try for Bluetooth, but i think should works) Brightness, Fn row, speakers, and mic mute.

**Do not turn the bottom OLED (`eDP-2`) on.** Link training on Intel PHY B freezes the compositor at login.

I didn't use the bottom OLED as this laptop I use for Win11 for better experience. 

## Hardware this targets

| Piece | Notes |
|--------|--------|
| Machine | ASUS Zenbook Duo UX8407AA |
| GPU | Intel Xe / Arc B390 (`xe`) |
| Panels | Two BOE 2880×1800@144 OLEDs (`eDP-1` top, `eDP-2` bottom) |
| Keyboard | Primax USB `0b05:1cd7` (`hid-generic`, not `hid-asus`) |
| Audio | SOF SoundWire CS42L43 + 2× CS35L56; ghost ACPI RT722 `SWD0` must stay hidden |
| Webcam | USB UVC `13d3:52b9` (no IPU7 package) |

Tested on Omarchy 4.0.0-1, Linux 7.1.8-arch1-3.

## Install

On an Omarchy (or similar Arch + Limine UKI) install:

```bash
git clone https://github.com/leies/linux-asusduo-ux8407.git
cd linux-asusduo-ux8407
sudo ./install.sh
```

Then reboot.

| Option | Effect |
|--------|--------|
| `--skip-uki` | Copy files but do not rebuild the UKI |
| `--no-fastfetch` | Leave `~/.bashrc` alone |

Existing files are copied to `~/.local/share/linux-asusduo-ux8407/backup-<timestamp>/` before overwrite.

## What I changed ?

### Display / boot freeze

- Kernel: `xe.enable_dpcd_backlight=1`, PSR / Panel Replay / DSB off, `video=eDP-2:d`
- Hyprland: `eDP-1` 2880×1800@144, scale 1.6, transform 2; `eDP-2` disabled
- `asus_screenpad` backlight is ignored (this is two full OLEDs, not a ScreenPad)

### Keyboard

`hid-asus` does not know product `1CD7`. A small HID helper talks report `0x5A` for Fn-lock and keyboard backlight. udev runs `/usr/local/bin/omarchy-ux8407-keyboard init` (encrypted home is not mounted that early).

| Key | Action |
|-----|--------|
| F1 | Speaker mute |
| F2 / F3 | Volume down / up |
| F4 | Keyboard backlight cycle |
| F5 / F6 | Brightness down / up |
| F8 | Screenshot |
| F9 | Toggle touchpad |
| F10 | Microphone mute |
| F12 | Display / hardware menu |

Hold Fn for real F1–F12 after keyboard init. Super+Ctrl+X still toggles dictation.

### Audio

Ghost Realtek RT722 (`_SB.PC00.HDAS.IDA.SNDW.SWD0`) is hidden with SSDT `ssdt-noswd0.aml` in the **early** (uncompressed) initramfs via mkinitcpio hook `acpi_override`. The real card is `sofsoundwire`.

### Sleep / lid

Lid close uses **s2idle** (confirmed on this machine: `PM: suspend entry (s2idle)` / `PM: suspend exit`, Wi‑Fi asleep, user slice frozen — not just DPMS).

Stock s2idle and S3 hung at `PM: suspend entry` while Xe display C-states (DC5/DC6) were still on. The installer sets `xe.enable_dc=0`, keeps display power wells on, stops `intel_lpmd` around suspend, and leaves lid-close → suspend enabled. Reboot after install so those Xe flags are on the cmdline.

Do **not** DPMS-off the OLED (that stayed black). The lid helper only locks and dims, then logind sleeps. The HID keyboard backlight is turned off for sleep (via `/usr/lib/systemd/system-sleep/`, which is what systemd actually runs) and restored on wake.

### Other

- `iwlwifi disable_11be=Y` — Wi-Fi 7 RX workaround on this Panther Lake generation
- `fastfetch` on interactive bash terminals
- Power: use `power-profiles-daemon` (`omarchy powerprofiles set battery power-saver`). Do not install TLP on top.

## After kernel / Omarchy updates

1. `limine-update` must still pick up `/etc/limine-entry-tool.d/asus-ux8407-display.conf`
2. Rebuild the UKI so `acpi_override` still ships the SSDT (`sudo limine-update`)
3. Do not re-enable `eDP-2` unless a later kernel actually trains PHY B

## Layout

```
install.sh                          one-shot installer
files/etc/                          system drop-ins (Limine, modprobe, udev, mkinitcpio)
files/usr/local/bin/                keyboard HID helper
files/home/                         Hyprland, user systemd unit, bashrc snippet
files/acpi/                         SSDT source + compiled AML
docs/PHASE1-STATUS.md               freeze-the-baseline notes
docs/history/readme.html            original step-by-step writeup
docs/history/scripts/               earlier apply attempts (do not run)
```

`docs/history/scripts/` is for study only. Several of those paths failed (blacklist forever, late ACPI, UKI `.acpi` section). The working path is `install.sh`.

## Intentionally not included

- Re-enabling the bottom screen
- Windows 11 Limine boot menu entry
- TLP
- Extra NVIDIA / IPU7 packages
- Dock-watch (it would turn `eDP-2` on when the keyboard undocks)
