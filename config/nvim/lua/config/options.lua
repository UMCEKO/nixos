-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = ".env*",
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Detect SSH
local function is_ssh()
  return os.getenv("SSH_TTY") ~= nil
end

if is_ssh() then
  -- Use OSC52 for clipboard in SSH
  local osc52 = require("vim.ui.clipboard.osc52")

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }

  -- Also set clipboard option
  vim.opt.clipboard:append("unnamedplus")
end
