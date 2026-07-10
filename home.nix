# home-manager config for umceko.
#
# Dotfiles strategy: riced configs live IN this repo at ~/nixos/config and are
# git-tracked with everything else (single source of truth — the flake only sees
# git-tracked files, so nothing can silently go missing). We LIVE-symlink them
# (mkOutOfStoreSymlink) ~/.config/<x> -> ~/nixos/config/<x>, so you still edit in
# place and commit them alongside the rest of the nix config.
{ config, pkgs, lib, inputs, ... }:
let
  # Live symlinks (writable) to ~/nixos/config. These MUST stay writable because
  # matugen writes color files into these dirs at runtime (hypr/waybar/rofi/wlogout/
  # nwg-dock/ohmyposh...) and nvim/fish write their own state — a read-only store
  # path would break both. Still one git-tracked repo; still live-editable.
  # (kitty/fastfetch/swaync are native modules below — matugen still works there
  # because modules write per-file into a real dir, so its color file sits alongside.)
  writableConfigs = [
    "hypr" "rofi" "wlogout"
    "matugen" "sidepad" "Iriun" "Kvantum" "vim" "ohmyposh" "nvim" "fish"
    # NOTE: "zshrc" removed — zsh is now a native programs.zsh module (below),
    # so home-manager writes ~/.zshrc directly. The old ~/.config/zshrc/*
    # modular files (ML4W, oh-my-posh) are no longer sourced.
    "ml4w" # NOT the ML4W rice — your de-ML4W'd configs still read its settings/library files
    "quickshell" # editable DMS fork (config/quickshell/dms) — dms-shell.service runs it via -c
    # Retired 2026-07-09 (→ DankMaterialShell): waybar, eww, swaync, waypaper,
    # networkmanager-dmenu, nwg-dock-hyprland, wpaperd. Dirs deleted from config/.
  ];

  # git credential helper backed by gnome-keyring. nixpkgs ships only the .c
  # source in git's contrib/, so compile it against libsecret + glib.
  git-credential-libsecret = pkgs.runCommand "git-credential-libsecret"
    { nativeBuildInputs = [ pkgs.gcc pkgs.pkg-config ];
      buildInputs = [ pkgs.glib pkgs.libsecret ]; }
    ''
      mkdir -p $out/bin
      gcc -o $out/bin/git-credential-libsecret \
        ${pkgs.git}/share/git/contrib/credential/libsecret/git-credential-libsecret.c \
        $(pkg-config --cflags --libs libsecret-1 glib-2.0)
    '';

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
  # HUSH: installs the `hush` GUI + runs the `hushd` denoiser as a user service
  # (the module bakes the runtime SDK dir into the unit's LD_LIBRARY_PATH; the SDK
  # itself is downloaded once by the app on first launch).
  imports = [ inputs.hush.homeManagerModules.default ];
  services.hush.enable = true;

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

    # KDE apps (Dolphin) read text/view colors from kdeglobals [Colors:*], NOT
    # from the Kvantum style — so Kvantum's dark bg + KDE's default light scheme
    # = dark-on-dark. This applies a matching dark scheme so text is readable.
    workspace.colorScheme = "CatppuccinMochaMauve";
  };

  # The scheme plasma-apply-colorscheme resolves the name above against.
  home.file.".local/share/color-schemes/CatppuccinMochaMauve.colors".source =
    ./config/color-schemes/CatppuccinMochaMauve.colors;

  # Stable path to proton-cachyos for umu-launcher (PROTONPATH) — survives
  # updates, unlike a raw /nix/store path. /bin is the compat-tool root.
  home.file.".local/share/proton-cachyos".source =
    "${inputs.chaotic.legacyPackages.${pkgs.system}.proton-cachyos_x86_64_v3}/bin";

  # OpenComposite (OpenVR->OpenXR shim) for VR_OVERRIDE consumers. Nix-built —
  # an Arch-built copy can't load here (glibc/GL deps), and nix store paths
  # stay visible inside the Steam Linux Runtime container.
  home.file.".local/share/opencomposite".source =
    "${pkgs.opencomposite}/lib/opencomposite";

  # Live symlinks to ~/nixos/config (writable — required for matugen + app state).
  xdg.configFile = lib.genAttrs writableConfigs (name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/${name}";
  });

  # Default browser = Brave. This writes ~/.config/mimeapps.list, which is the
  # real "default browser" for the desktop: http/https links, .html files, and
  # apps that call xdg-open all resolve here. (The BROWSER=brave env var in
  # configuration.nix only covers terminal programs — separate mechanism.)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http"  = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "text/html"              = "brave-browser.desktop";
      "application/xhtml+xml"  = "brave-browser.desktop";
      "inode/directory"        = "org.gnome.Nautilus.desktop";  # not Dolphin
    };
  };

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

  # ── zsh — native port of your CachyOS ~/.zshrc (was oh-my-zsh + starship) ──
  # Previously ~/.zshrc did `[ -f ~/.config/zshrc ] && source …`, but that path
  # was a *directory* (the ML4W modular files), so nothing actually loaded.
  # Now home-manager owns ~/.zshrc via this module. Same tools you had on Cachy:
  # oh-my-zsh (git plugin) + autosuggestions + syntax highlighting, prompt = starship.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # was zsh-autosuggestions from /usr/share
    syntaxHighlighting.enable = true;  # was fast-syntax-highlighting
    history = { size = 10000; save = 10000; };  # matches your HISTSIZE/SAVEHIST

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];  # your active .zshrc used plugins=(git)
      theme = "";           # empty: OMZ sets no prompt — starship owns it
    };

    shellAliases = {
      c = "clear";
      nf = "fastfetch"; pf = "fastfetch"; ff = "fastfetch";
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      v = "$EDITOR"; vim = "$EDITOR";
      wifi = "nmtui";
      shutdown = "systemctl poweroff";
      k = "kubectl";
      # git (from your CachyOS .zshrc)
      gs = "git status"; ga = "git add"; gc = "git commit -m";
      gp = "git push"; gpl = "git pull"; gst = "git stash";
      gsp = "git stash; git pull"; gfo = "git fetch origin";
      gcheck = "git checkout";
      gcredential = "git config credential.helper store";
      # Dropped as CachyOS/ML4W/qtile-specific (didn't carry over to NixOS):
      #   ml4w* (flatpak apps), ts/cleanup/ascii/ml4w-update (~/.config/ml4w scripts),
      #   Qtile=startx, res1/res2, setkb (X11/qtile — you're on Wayland),
      #   update-grub (NixOS uses systemd-boot, not grub).
    };

    initContent = ''
      # PATH additions from your CachyOS .zshrc (bun/ccache dropped — not installed)
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
      setopt append_history

      # pyenv (installed via nix; init still works even without $PYENV_ROOT/bin)
      export PYENV_ROOT="$HOME/.pyenv"
      [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init - zsh)"

      # md(): render a markdown file to HTML and open it (needs pandoc).
      # unalias first — NixOS's /etc/zshrc defines md='mkdir -p', and without
      # this the function definition is a parse error that aborts the rest of
      # ~/.zshrc (this mirrors your CachyOS .zshrc, which also unaliased md).
      unalias md 2>/dev/null
      md() { pandoc "$1" -s -o /tmp/md.html && xdg-open /tmp/md.html; }

      # fastfetch greeting on interactive shells (your CachyOS autostart)
      if [[ -o interactive ]]; then
        fastfetch
      fi
    '';
  };

  # starship prompt — this was the prompt in your most-recent CachyOS ~/.zshrc
  # (`eval "$(starship init zsh)"`). No ~/.config/starship.toml existed, so it
  # ran on the default preset — same here (add programs.starship.settings to tune).
  programs.starship.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "umutcevdetkocak@gmail.com";
        name = "umceko";
      };
      # Empty so git prompts on the tty instead of the broken ksshaskpass that
      # plasma6 exports globally (its Qt portal can't register under Hyprland).
      core.askpass = "";
      credential = {
        # Every host → gnome-keyring (asked once per host). github uses gh's
        # OAuth token instead; leading "" resets libsecret so only gh answers.
        helper = "${git-credential-libsecret}/bin/git-credential-libsecret";
        "https://github.com".helper = [ "" "!gh auth git-credential" ];
        "https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
      };
    };
  };

  # DMS unit with no WantedBy — autostart.lua starts it, so it only runs under
  # Hyprland, never KDE (see dms.nix). Restart=on-failure adds crash recovery.
  systemd.user.services.dms-shell = {
    Unit = {
      Description = "DankMaterialShell (Hyprland session)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # -c points at the editable clone (config/quickshell/dms, live-symlinked to
      # ~/.config/quickshell/dms). The dms wrapper hardcodes -c <store>; a second
      # -c wins, so this overrides it. Lets us hand-edit the QML. NOTE: on a
      # dms-shell package bump, re-sync the clone from the new store path.
      ExecStart = "${pkgs.dms-shell}/bin/dms run --session -c ${config.home.homeDirectory}/.config/quickshell/dms";
      Restart = "on-failure";
      RestartSec = 2;
      Slice = "session.slice";
    };
    # deliberately no Install.WantedBy — started from Hyprland autostart only.
  };

  # (chatmix-setup service retired — the chatmixd daemon (flake input) creates
  # the Game/Chat sinks itself on first dial input; the old ~/.local/bin script
  # was never copied and the unit failed every boot.)

  # (wallpaper-rotate script + timer retired — DMS draws + cycles wallpaper now)

  # OLED burn-in: shift pixels in the bar area hourly (your old hyproled units).
  # DISABLED 2026-07-08 (per request). Re-enable by uncommenting all three below;
  # the `hyproled` derivation up top stays defined and ready.
  # home.packages = [ hyproled ];
  # systemd.user.services.hyproled = {
  #   Unit.Description = "Shift OLED pixels on bar area";
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${hyproled}/bin/hyproled -s -m 0 -a 0:0:3840:75";
  #   };
  # };
  # systemd.user.timers.hyproled = {
  #   Unit.Description = "Hourly OLED pixel shift for bar area";
  #   Timer = { OnBootSec = "5min"; OnUnitActiveSec = "1h"; Persistent = true; };
  #   Install.WantedBy = [ "timers.target" ];
  # };
}
