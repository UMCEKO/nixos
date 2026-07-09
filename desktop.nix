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

    # Hyprland portal routing — else plasma6's KDE config (default=kde,
    # Secret=kwallet) bleeds into the Hyprland session.
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # Fonts (replaces the ttf-* / nerd-font Arch packages).
  fonts.packages = with pkgs; [
    ubuntu-sans nerd-fonts.ubuntu   # hyprpanel-look font for the waybar clone
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
    # Carried over from the CachyOS install (were pacman ttf-* packages there).
    poppins                          # geometric sans display font
    hack-font                        # KWrite editor "Text Font=Hack"
    nerd-fonts.fantasque-sans-mono   # ttf-fantasque-nerd
    carlito                          # Calibri-metric-compatible sans
  ];

  # Reject Unifont (NixOS default fallback) — its hex-box glyphs for uncovered
  # codepoints showed as garbage in Discord. CachyOS never had it.
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <selectfont>
        <rejectfont>
          <pattern>
            <patelt name="family"><string>Unifont</string></patelt>
          </pattern>
        </rejectfont>
      </selectfont>
    </fontconfig>
  '';

  # Qt theming: Kvantum draws widgets (QT_STYLE_OVERRIDE), but the *palette*
  # (text colors!) comes from the platform theme. qt5ct/qt6ct shipped a light
  # palette -> dark text on Kvantum's dark bg. kde = plasma-integration, which
  # reads kdeglobals — where plasma-manager applies CatppuccinMochaMauve.
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "kvantum";
  };
}
