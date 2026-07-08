-- lua/plugins/dadbod.lua
return {
  -- Core dadbod plugin
  {
    "tpope/vim-dadbod",
  },

  -- Dadbod UI for better database interaction
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_winwidth = 40
      vim.g.db_ui_notification_width = 39
    end,
  },

  -- Completion for dadbod
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = { "tpope/vim-dadbod", "hrsh7th/nvim-cmp" },
    ft = { "sql", "mysql", "plsql" },
    config = function()
      vim.g.db_completion_enabled = 1

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          -- Also set omnifunc as fallback (nvim-cmp handles primary completion usually)
          vim.bo.omnifunc = "vim_dadbod_completion#omni"

          -- Debug: Print that autocmd fired
          print("SQL FileType autocmd fired - sources configured")
        end,
      })
    end,
  },

  -- Additional SQL keyword completion (800+ keywords) - Keep this plugin as it provides the 'sql' source
  {
    "ray-x/cmp-sql",
    dependencies = { "hrsh7th/nvim-cmp" },
    ft = { "sql", "mysql", "plsql" },
    -- No config needed here, it just provides the 'sql' source
  },
}
