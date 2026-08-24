-- Persistent workspace → monitor mapping — per host (see lua/host.lua).
--
-- Desktop (2 monitors):
--   Main monitor (Samsung DP-3):    workspaces 1-10
--   Secondary monitor (ASUS DP-4):  workspaces 11-20
--
-- Laptop (1 panel): everything on eDP-1, workspaces 1-10.
--   The desktop's DP-3/DP-4 rules used to apply here as well. DP-3 and DP-4 are
--   REAL connector names on this laptop (USB-C DP alt mode) that just happen to
--   be disconnected, so the rules were neither matched nor ignored: persistence
--   silently died (ws 10 never existed, strays like 11 and 21 piled onto eDP-1),
--   and scripts/switch-workspace.sh — which derives its base from the lowest
--   workspace id bound to the focused monitor — got a polluted range to work
--   from. Docking a USB-C display would have yanked 1-10 onto it mid-session.
local host = require("host")

local function bind(first, last, monitor)
  for i = first, last do
    hl.workspace_rule({
      workspace  = tostring(i),
      monitor    = monitor,
      persistent = true,
    })
  end
end

if host.is_laptop then
  bind(1, 10, "eDP-1")
else
  bind(1, 10, "DP-3")
  bind(11, 20, "DP-4")
end
