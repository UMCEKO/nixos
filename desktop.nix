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

    # Hyprland-session portal routing. Without this, plasma6's KDE portal config
    # (default=kde, Secret=kwallet) is applied to the Hyprland session too —
    # screencast/screenshot go through the KDE portal (wrong for Hyprland) and
    # the Secret portal prompts for kwallet even though gnome-keyring is our
    # Secret Service. Route screen* to hyprland's portal and Secret to
    # gnome-keyring; everything else falls back hyprland -> gtk.
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

  # Reject Unifont from the fallback chain. NixOS's fonts.enableDefaultPackages
  # (on by default) pulls in Unifont as a last-resort fallback; CachyOS never
  # had it. The difference: for codepoints no real font covers (unassigned ones,
  # rare scripts, exotic symbols), Unifont draws a box with the hex number inside
  # — which showed up as "wrong-looking characters" in Discord. Rejecting it makes
  # those render as a plain blank box, matching how CachyOS behaved.
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

  # Qt theming (Kvantum) — GTK/Qt look from your dotfiles.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
}
