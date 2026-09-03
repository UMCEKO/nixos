-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = ".env*",
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Gate on whether a real clipboard tool is reachable, not on SSH: tmux panes spawned
-- from a tty inherit no WAYLAND_DISPLAY, so wl-copy is missing while SSH_* is also unset.
local function has_native_clipboard()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT then
    return false
  end
  if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
    return true
  end
  if vim.env.DISPLAY and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1) then
    return true
  end
  return false
end

if not has_native_clipboard() then
  local osc52 = require("vim.ui.clipboard.osc52")

  -- OSC 52 reads are not forwarded by tmux and would hang; mirror the unnamed register instead
  local function paste()
    return vim.split(vim.fn.getreg("") or "", "\n")
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

vim.opt.clipboard = "unnamedplus"
