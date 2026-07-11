vim.opt.exrc = true
vim.opt.secure = true -- Recommended with exrc

-- postgres_lsp is configured via the nvim-lspconfig spec (plugins/lsp.lua);
-- requiring lspconfig here loads it before snacks.nvim and crashes LazyVim.
vim.diagnostic.config({
  float = {
    focusable = true, -- Set this to true
    source = true,
    border = "rounded",
  },
})

vim.filetype.add({
  extension = {
    m = "matlab",
  },
})

vim.lsp.config("matlab_ls", {
  settings = {},
})

vim.lsp.enable("matlab_ls")
