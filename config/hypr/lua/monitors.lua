-- Monitor layout — per host (see lua/host.lua).
--
-- Desktop: matched by description (serial), NOT port — DP-x renumbers on reconnect.
--   ASUS PA279 (secondary, left),        4K@60,  scale 2
--   Samsung Odyssey G81SF (main, right), 4K@240, scale 1.5
--
-- Laptop: one built-in panel. The desktop's two monitor blocks used to apply
-- here too and matched nothing, so the panel fell through to Hyprland's
-- autodetect with no declared mode/scale.
local host = require("host")

if host.is_laptop then
  -- HP EliteBook 6 G1a — 14" WUXGA. 1.5 is what Hyprland autodetects and what
  -- 1920x1200 on a 14" panel wants; declared here so it is not luck.
  hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1.5 })

  -- Catch-all so anything hotplugged into the USB-C/HDMI ports (DP-1..DP-7,
  -- HDMI-A-1 all exist as connectors on this box) comes up to the right of the
  -- panel at native res instead of mirroring or staying dark.
  hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })
else
  hl.monitor({ output = "desc:ASUSTek COMPUTER INC ASUS PA279 0x00027393",            mode = "3840x2160@60",  position = "0x0",    scale = 2   })
  hl.monitor({ output = "desc:Samsung Electric Company Odyssey G81SF HNBY800179", mode = "3840x2160@240", position = "1920x0", scale = 1.5 })
end
