-- Keyboard / mouse / touchpad (from conf/keyboard.conf)

local host = require("host")

hl.config({
  input = {
    kb_layout          = "us,tr",
    kb_variant         = ",",
    kb_model           = "",
    kb_options         = "",
    numlock_by_default = true,
    follow_mouse       = 1,
    mouse_refocus      = false,
    -- Tuned for the Razer DeathAdder, which is used on BOTH machines, so these
    -- stay shared. NOTE: accel_profile is global in Hyprland — there is no
    -- input:touchpad:accel_profile — so "flat" also lands on the touchpad. If
    -- the touchpad ever feels like it needs too many swipes to cross the
    -- screen, that is this line, and fixing it properly means a per-device
    -- block rather than flipping it here and ruining the mouse.
    sensitivity        = -0.200,  -- matched from KDE
    accel_profile      = "flat",
    touchpad = {
      natural_scroll = false,  -- matches the mouse; flip per host if you prefer
      scroll_factor  = 1.0,
    },
  },
})

-- Touchpad quality-of-life. Single-panel hosts only — the desktop has no
-- touchpad, and these keys would sit there describing hardware that does not
-- exist. (syna3143:00-06cb:d004-touchpad on the EliteBook.)
if host.is_laptop then
  hl.config({
    input = {
      touchpad = {
        tap_to_click         = true,
        tap_and_drag         = true,
        drag_lock            = true,
        disable_while_typing = true,
        -- Two fingers = right click, instead of dividing the bottom edge into
        -- click zones. The zones are the default and are easy to hit by
        -- accident with a resting thumb.
        clickfinger_behavior = true,
      },
    },
  })
end

-- XWayland (was in conf/ml4w.conf)
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})
