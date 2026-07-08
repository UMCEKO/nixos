return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        "dockerfile-language-server",
        "eslint-lsp",
        "eslint_d",
        "hadolint",
        "kube-linter",
        "lua-language-server",
        "prettier",
        "shfmt",
        "stylua",
        "tailwindcss-language-server",
        "typescript-language-server",
        "yamlls",
        "just-lsp",
      },
      run_on_start = true,
      auto_update = true,
    })
  end,
}
