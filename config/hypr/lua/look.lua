-- General + decoration (from conf/windows/default.conf, conf/decorations/default.conf)

-- Material colors used for borders (from colors.conf)
local color_active   = "rgba(ede0d4ff)"  -- $on_surface
local color_inactive = "rgba(f5bc6fff)"  -- $primary

hl.config({
  general = {
    gaps_in     = 10,
    gaps_out    = 20,
    border_size = 3,
    col = {
      active_border   = color_active,
      inactive_border = color_inactive,
    },
    layout            = "dwindle",
    resize_on_border  = true,
    no_focus_fallback = true,  -- from custom-settings.conf
  },

  decoration = {
    rounding           = 10,
    active_opacity     = 1.0,
    inactive_opacity   = 0.9,
    fullscreen_opacity = 1.0,

    blur = {
      enabled           = true,
      size              = 6,
      passes            = 2,
      new_optimizations = true,
      ignore_opacity    = true,
      xray              = true,
    },

    shadow = {
      enabled      = true,
      range        = 10,
      render_power = 2,
      color        = 0x33000000,
    },
  },
})
