-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- ASUS Zenbook Duo UX8407AA: F-row matches the printed hotkeys (Fn-lock on).
-- Hold Fn for the real F1–F12 once the keyboard HID init has run.
-- F9 was voxtype push-to-talk; Super+Ctrl+X still toggles dictation.
hl.unbind("F9")
hl.unbind("XF86KbdLightOnOff")

o.bind("F1", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("F2", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("F3", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("F4", "Keyboard backlight", "/usr/local/bin/omarchy-ux8407-keyboard kbd-backlight cycle", { locked = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight", "/usr/local/bin/omarchy-ux8407-keyboard kbd-backlight cycle", { locked = true })
o.bind("F5", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("F6", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("F8", "Screenshot", "omarchy-capture-screenshot", { locked = true })
o.bind("F9", "Toggle touchpad", "omarchy-toggle-touchpad", { locked = true })
o.bind("F10", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
o.bind("F12", "Display", "omarchy-menu toggle hardware", { locked = true })

-- Lock and restore the panel around lid events. logind then suspends.
-- Default was omarchy-system-lid-close / omarchy-hyprland-monitor-clamshell.
hl.unbind("switch:on:Lid Switch")
hl.unbind("switch:off:Lid Switch")
o.bind("switch:on:Lid Switch", nil, os.getenv("HOME") .. "/.local/bin/omarchy-ux8407-lid close", { locked = true })
o.bind("switch:off:Lid Switch", nil, os.getenv("HOME") .. "/.local/bin/omarchy-ux8407-lid open", { locked = true })
