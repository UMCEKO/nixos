# LSP servers, formatters and linters for your Neovim config, installed via nix
# instead of mason (mason's prebuilt binaries don't run on NixOS).
# These are the exact tools from your nvim mason-tool-installer + lspconfig setup.
# The matching nvim change disables mason on NixOS: see
#   ~/dotfiles/config/nvim/lua/plugins/nix-no-mason.lua
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # ── LSP servers ──
    lua-language-server
    yaml-language-server
    dockerfile-language-server
    tailwindcss-language-server
    vscode-langservers-extracted     # html / css / json / eslint LSPs
    helm-ls
    just-lsp
    postgres-language-server
    matlab-language-server
    gopls                            # you do Go dev
    # typescript-language-server, vtsls, rust-analyzer already in packages.nix

    # ── Formatters / linters ──
    prettier
    eslint_d
    stylua
    shfmt
    hadolint
    kube-linter
  ];
}
