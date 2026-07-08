-- Persistent workspace → monitor mapping (from scripts/ssw.conf)
-- DISPLAYS: ASUS PA279, Samsung Odyssey G81SF
-- Main monitor (Samsung DP-3): workspaces 1-10
-- Secondary monitor (ASUS DP-4):  workspaces 11-20

for i = 1, 10 do
  hl.workspace_rule({
    workspace  = tostring(i),
    monitor    = "DP-3",
    persistent = true,
  })
end

for i = 11, 20 do
  hl.workspace_rule({
    workspace  = tostring(i),
    monitor    = "DP-4",
    persistent = true,
  })
end
