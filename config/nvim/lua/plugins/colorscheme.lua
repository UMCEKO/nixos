return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_colors = function(colors)
        local Util = require("tokyonight.util")

        -- Shift all background colors so bg_dark1 (#191B29) becomes #000000
        -- Per-channel offset subtracted: R-25, G-27, B-41
        colors.bg_dark1 = "#000000"
        colors.bg_dark = "#050507"
        colors.bg = "#09090d"
        colors.bg_highlight = "#161824"

        -- Update Util.bg so inline blend calculations use the new background
        Util.bg = colors.bg

        -- Re-derive colors that depend on bg/bg_dark
        colors.black = Util.blend_bg(colors.bg, 0.8, "#000000")
        colors.border = colors.black
        colors.bg_popup = colors.bg_dark
        colors.bg_statusline = colors.bg_dark
        colors.bg_sidebar = colors.bg_dark
        colors.bg_float = colors.bg_dark
        colors.bg_visual = Util.blend_bg(colors.blue0, 0.4)
        colors.diff = {
          add = Util.blend_bg(colors.green2, 0.25),
          delete = Util.blend_bg(colors.red1, 0.25),
          change = Util.blend_bg(colors.blue7, 0.15),
          text = colors.blue7,
        }
      end,
    },
  },
}
