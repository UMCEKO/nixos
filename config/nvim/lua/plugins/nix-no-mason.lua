-- On NixOS, mason downloads prebuilt binaries that can't execute (there's no
-- /usr/lib and no /lib64/ld-linux loader). So we install LSPs/formatters/linters
-- via nix (see ~/nixos/nvim-lsp.nix) and disable mason's install machinery here.
--
-- Guarded on /etc/NIXOS so this file is a no-op on any non-NixOS machine —
-- your config stays portable and mason still works elsewhere.
if vim.fn.filereadable("/etc/NIXOS") == 0 then
  return {}
end

return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
}
