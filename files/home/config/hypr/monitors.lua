-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Top OLED only. Bottom panel (eDP-2) stays off: enabling it wedges PHY B
-- and freezes the compositor at login.
hl.monitor({
  output = "eDP-1",
  mode = "2880x1800@144",
  position = "0x0",
  scale = omarchy_monitor_scale,
  transform = 2,
})
hl.monitor({ output = "eDP-2", disabled = true })

-- External displays still auto-place.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
