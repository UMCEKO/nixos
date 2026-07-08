-- Misc settings (from conf/misc.conf)

hl.config({
  misc = {
    disable_hyprland_logo       = true,
    disable_splash_rendering    = true,
    initial_workspace_tracking  = 1,
    -- VRR mode 2 = on for fullscreen apps only. Required for G-Sync on the
    -- Samsung G81SF OLED; eliminates compositor-driven frame pacing while gaming.
    vrr                         = 2,
  },
})

-- Direct scanout: when a fullscreen app is the only thing drawing on a monitor,
-- hand its buffer straight to the display, bypassing composition. Massive
-- latency/stutter improvement under games. Watch `hyprctl monitors | grep solitary`
-- to confirm engagement when fullscreen.
hl.config({
  render = {
    direct_scanout = 1,
  },
})
