-- Keyboard / mouse / touchpad (from conf/keyboard.conf)

hl.config({
  input = {
    kb_layout          = "us,tr",
    kb_variant         = ",",
    kb_model           = "",
    kb_options         = "",
    numlock_by_default = true,
    follow_mouse       = 1,
    mouse_refocus      = false,
    sensitivity        = -0.200,  -- matched from KDE
    accel_profile      = "flat",
    touchpad = {
      natural_scroll = false,
      scroll_factor  = 1.0,
    },
  },
})

-- XWayland (was in conf/ml4w.conf)
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})
