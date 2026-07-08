vim.opt.exrc = true
vim.opt.secure = true -- Recommended with exrc

local lspconfig = require("lspconfig")

lspconfig.postgres_lsp.setup({
  settings = {
    ["postgres-language-server"] = {},
  },
  filetypes = { "sql", "pgsql", "postgres", "sql.dockerfile" },
})
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
