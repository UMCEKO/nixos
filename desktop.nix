# Desktop: Hyprland (your lua config lives in ~/dotfiles) alongside the
# existing KDE Plasma 6 (configured in configuration.nix). SDDM lets you
# pick either session at login.
{ pkgs, ... }:
{
  # Hyprland compositor. This also wires xdg-desktop-portal-hyprland.
  programs.hyprland = {
    enable = true;
    withUWSM = true;   # session manager; clean env for Wayland
  };

  # NOTE: hyprlandPlugins.hyprsplit (per-monitor workspaces) doesn't compile
  # against hyprland 0.55 in nixpkgs 26.05 yet — revisit after channel bump.
  # Until then switch-workspace.sh derives mapping from live hyprctl state.

  # Portals (screen share, file pickers). KDE portal comes from plasma6.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Fonts (replaces the ttf-* / nerd-font Arch packages).
  fonts.packages = with pkgs; [
    fira-sans          # waybar ml4w themes use "Fira Sans Semibold"
    fira-code
    nerd-fonts.fira-code
    roboto             # theme fallback chain
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    dejavu_fonts
    liberation_ttf
    open-sans
    cantarell-fonts
  ];

  # Qt theming (Kvantum) — GTK/Qt look from your dotfiles.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
}
