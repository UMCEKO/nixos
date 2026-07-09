return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = { "rust", "ron" },
    install_dir = vim.fn.stdpath("data") .. "/site",
  },
}
