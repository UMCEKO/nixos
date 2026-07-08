# home-manager config for umceko.
#
# Dotfiles strategy: riced configs live IN this repo at ~/nixos/config and are
# git-tracked with everything else (single source of truth — the flake only sees
# git-tracked files, so nothing can silently go missing). We LIVE-symlink them
# (mkOutOfStoreSymlink) ~/.config/<x> -> ~/nixos/config/<x>, so you still edit in
# place and commit them alongside the rest of the nix config.
{ config, pkgs, lib, ... }:
let
  # Live symlinks (writable) to ~/nixos/config. These MUST stay writable because
  # matugen writes color files into these dirs at runtime (hypr/waybar/rofi/wlogout/
  # nwg-dock/ohmyposh...) and nvim/fish write their own state — a read-only store
  # path would break both. Still one git-tracked repo; still live-editable.
  # (kitty/fastfetch/swaync are native modules below — matugen still works there
  # because modules write per-file into a real dir, so its color file sits alongside.)
  writableConfigs = [
    "hypr" "waybar" "rofi" "wlogout" "swaync" "waypaper" "nwg-dock-hyprland"
    "matugen" "sidepad" "Iriun" "Kvantum" "vim" "ohmyposh" "nvim" "fish" "zshrc"
    "ml4w" # NOT the ML4W rice — your de-ML4W'd configs still read its settings/library files
    "wpaperd" # wallpaper daemon with built-in rotation (replaced awww+rotate-timer)
  ];

  # hyproled — OLED burn-in shader (github.com/mklan/hyproled). Packaged from
  # source since it's not in nixpkgs. Wrapped with hyprctl on PATH.
  hyproled = pkgs.stdenv.mkDerivation {
    pname = "hyproled";
    version = "unstable-2026-07-05";
    src = pkgs.fetchFromGitHub {
      owner = "mklan";
      repo = "hyproled";
      rev = "5fd505a3108e3d52085915f28fe7c10ba9392f01";
      sha256 = "0crqjkybyygvqlrjhr9yrd0r1lslkglwlpq41v5gjhf8c9im5il7";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontBuild = true;
    installPhase = ''
      install -Dm755 hyproled $out/bin/hyproled
      wrapProgram $out/bin/hyproled \
        --prefix PATH : ${lib.makeBinPath [ pkgs.hyprland pkgs.gnugrep pkgs.gawk pkgs.coreutils ]}
    '';
  };
in
{
  home.stateVersion = "26.05";

  # KDE is now managed declaratively by plasma-manager (see rc2nix workflow),
  # so KDE rc files are NOT symlinked here anymore.
  programs.plasma = {
    enable = true;

    # Keyboard layouts (us + Turkish) with your switch shortcut — this is the
    # persistent, reproducible source of truth (writes kxkbrc on rebuild).
    input.keyboard.layouts = [
      { layout = "us"; displayName = "en"; }   # English Q
      { layout = "tr"; displayName = "tr"; }   # Turkish Q (default variant, not F)
    ];
    shortcuts."KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Space";
  };

  # Live symlinks to ~/nixos/config (writable — required for matugen + app state).
  xdg.configFile = lib.genAttrs writableConfigs (name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/${name}";
  });

  # ── Native home-manager modules (the nix-y way; matugen-safe per-file writes) ──
  programs.kitty = {
    enable = true;
    font = { name = "JetBrainsMono Nerd Font"; size = 12; };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      remember_window_size = "no";
      initial_window_width = 950;
      initial_window_height = 500;
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = 1;
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      enable_audio_bell = "no";
      window_padding_width = 10;
      hide_window_decorations = "yes";
      background_opacity = "0.7";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = 0;
      selection_foreground = "none";
      selection_background = "none";
    };
    extraConfig = ''
      include colors-matugen.conf
      cursor_trail 1
    ''; # colors: matugen writes at runtime; cursor_trail: animated cursor from your cachy setup
  };

  programs.fastfetch.settings =
    builtins.fromJSON (builtins.readFile ./config/fastfetch/config.json);

  # NOTE: swaync is NOT a systemd module — that would run it in the KDE session
  # too (conflicting with KDE notifications). It's a writable-symlink config
  # launched only from Hyprland's autostart. (services.swaync would be session-agnostic.)

  # zsh was your login shell on CachyOS. Your zsh config lives at ~/.config/zshrc,
  # so point ~/.zshrc at it.
  home.file.".zshrc".text = ''
    [ -f "$HOME/.config/zshrc" ] && source "$HOME/.config/zshrc"
  '';

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "umutcevdetkocak@gmail.com";
        name = "umceko";
      };
    };
  };

  # ── User services ported from CachyOS (~/.config/systemd/user) ──
  # These run scripts in ~/.local/bin (copied over). Proper nixification
  # (writeShellApplication with pinned runtimeInputs) is a follow-up.
  systemd.user.services.chatmix-setup = {
    Unit = {
      Description = "Create ChatMix sinks routed to Arctis Nova 7";
      After = [ "pipewire-pulse.service" "wireplumber.service" ];
      Requires = [ "pipewire-pulse.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.home.homeDirectory}/.local/bin/chatmix-setup.sh";
      Environment = "PATH=/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # (wallpaper-rotate script + timer retired — wpaperd rotates natively now)

  # OLED burn-in: shift pixels in the bar area hourly (your old hyproled units).
  home.packages = [ hyproled ];
  systemd.user.services.hyproled = {
    Unit.Description = "Shift OLED pixels on bar area";
    Service = {
      Type = "oneshot";
      ExecStart = "${hyproled}/bin/hyproled -s -m 0 -a 0:0:3840:75";
    };
  };
  systemd.user.timers.hyproled = {
    Unit.Description = "Hourly OLED pixel shift for bar area";
    Timer = { OnBootSec = "5min"; OnUnitActiveSec = "1h"; Persistent = true; };
    Install.WantedBy = [ "timers.target" ];
  };
}
