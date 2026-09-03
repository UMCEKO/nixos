# home-manager config for umceko — SHARED BY BOTH HOSTS.
#
# Anything needing the nvidia GPU, the Steam library or VR hardware lives in
# hosts/desktop/home.nix instead. That split is not cosmetic: HUSH is a Maxine
# denoiser that requires CUDA, and proton-cachyos pulls a multi-GB compat tool
# from chaotic's cache — neither belongs on an all-AMD laptop.
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
    "DankMaterialShell" # DMS settings (settings.json etc.) — DMS writes these at runtime
    "danksearch" # dsearch config.toml
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

  # ── Per-host DMS settings ──────────────────────────────────────────────
  # config/DankMaterialShell/settings.json is SHARED and is written by DMS
  # itself at runtime, which is what we want for ~375 of its 381 keys: tune the
  # bar on one machine, `git pull` on the other, done. The handful that describe
  # the MACHINE rather than the rice cannot work that way — which NIC to prefer,
  # which monitor matugen samples, whether there is a battery or a discrete GPU.
  # Those live in config/DankMaterialShell/hosts/<hostname>.json and are merged
  # over the shared file immediately before DMS reads it.
  #
  # See config/DankMaterialShell/hosts/README.md for the workflow.
  dmsHostSettings = pkgs.writeShellScript "dms-apply-host-settings" ''
    set -eu
    dir="$HOME/nixos/config/DankMaterialShell"
    base="$dir/settings.json"
    over="$dir/hosts/$(cat /etc/hostname).json"
    [ -f "$base" ] && [ -f "$over" ] || exit 0

    # `*` is jq's RECURSIVE merge: nested objects are patched key-by-key rather
    # than replaced wholesale, so a host file can override one field of
    # screenPreferences without restating the rest of it.
    merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$base" "$over")

    # No-op if nothing would change. Without this, every activation and every
    # DMS restart would bump the mtime of a git-tracked file for nothing — and
    # DMS watches this file, so a pointless write is a pointless reload.
    [ "$merged" = "$(cat "$base")" ] && exit 0

    # DMS writes this file with NO trailing newline. Match it byte for byte
    # (printf, not echo) or the merge itself shows up as a one-line diff.
    printf '%s' "$merged" > "$base.new"
    mv -f "$base.new" "$base"
  '';

  # git clean filter for the same file: strips every key any host overrides on
  # the way into the index. The host-specific values therefore never reach git,
  # so the two machines cannot fight over them and `git diff` on settings.json
  # only ever shows real, shared changes.
  #
  # The key list is DERIVED from hosts/*.json rather than written out again
  # here — one source of truth, and adding a key to the host files is all it
  # takes. git runs clean filters from the repo root, hence the relative path.
  dmsSettingsClean = pkgs.writeShellScript "dms-settings-clean" ''
    set -eu
    set -- config/DankMaterialShell/hosts/*.json
    [ -e "$1" ] || exec cat            # no host files yet: pass through
    keys=$(${pkgs.jq}/bin/jq -s 'add | keys' "$@")
    exec ${pkgs.jq}/bin/jq --argjson k "$keys" 'delpaths([$k[] | [.]])'
  '';

in
{
  home.stateVersion = "26.05";

  # KDE/Plasma is managed declaratively by plasma-manager. The whole captured
  # setup — shortcuts, panel, app prefs — lives in ./plasma.nix, which also
  # documents the rc2nix workflow for folding in future GUI changes.
  imports = [ ./plasma.nix ];

  # The scheme workspace.colorScheme in ./plasma.nix resolves against.
  home.file.".local/share/color-schemes/CatppuccinMochaMauve.colors".source =
    ../config/color-schemes/CatppuccinMochaMauve.colors;

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

  # enable = true is required: the home-manager module only writes
  # ~/.config/fastfetch/config.jsonc when it's on — `settings` alone is inert,
  # which is why the custom layout never showed up and the default one did.
  programs.fastfetch = {
    enable = true;
    settings = builtins.fromJSON (builtins.readFile ../config/fastfetch/config.json);
  };

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
      # cargo builds LOCALLY (default toolchain, currently 1.97.1). The Arch-box
      # (192.168.0.3) offload shim is still installed — invoke it explicitly with
      # `cargo-arch build/check/…` when you want the remote build.
      # (was: cargo = "cargo-arch";)
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
      # Strips the host-overridden DMS keys on the way into the index — see
      # the dmsSettingsClean comment above and .gitattributes.
      filter.dms-settings.clean = "${dmsSettingsClean}";
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
      # Stamp the host-specific keys over the shared settings.json BEFORE DMS
      # reads it. This is the one that matters: whatever value the other
      # machine last committed, this host starts with its own.
      ExecStartPre = "${dmsHostSettings}";
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

  # DMS editable clone: relink the heavy read-only assets from the packaged
  # dms-shell on every activation.
  #
  # dms-shell.service runs the clone at ~/.config/quickshell/dms (-c above), and
  # DMS loads its fonts by RELATIVE PATH, not by fontconfig family:
  #   Widgets/DankIcon.qml    -> ../assets/fonts/material-design-icons/...MaterialSymbolsRounded...ttf
  #   Widgets/StyledText.qml  -> ../assets/fonts/inter/InterVariable.ttf
  #                              ../assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf
  # .gitignore excludes config/quickshell/dms/assets (and translations) as
  # "heavy binary assets", so a fresh clone of this repo has no assets/ at all —
  # every FontLoader resolves to nothing and EVERY ICON IN DMS DISAPPEARS. That
  # is exactly what happened on the laptop's first install; the desktop only
  # looked fine because its assets/ was left over, untracked, from the original
  # copy out of the store. Adding material-symbols/inter to fonts.packages does
  # NOT fix this — the FontLoader wants that path, not a font family.
  #
  # Symlinking from the pinned package makes the .gitignore comment true and
  # ties the assets to the same dms-shell version everything else uses. Done in
  # an activation script rather than xdg.configFile because ~/.config/quickshell
  # is itself one mkOutOfStoreSymlink (see writableConfigs) and home-manager
  # cannot place a file inside it.
  #
  # NOTE: the clone is currently v1.4.6 against a v1.5.3 package — re-sync it
  # (see the ExecStart comment above) or drop the -c override entirely.
  home.activation.dmsCloneAssets =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      clone="$HOME/nixos/config/quickshell/dms"
      if [ -d "$clone" ]; then
        # NOT plain `ln -sfn`: against an EXISTING REAL DIRECTORY that creates
        # the link *inside* it (assets/assets -> ...) and exits 0, so the fix
        # silently does nothing. Both hosts had a real assets/ dir — an
        # untracked copy left over from when the clone was made — so this is
        # the normal case on first activation, not an edge case.
        relink() {
          if [ -L "$2" ]; then
            run ln -sfn "$1" "$2"
          elif [ -e "$2" ]; then
            # Preserve the old copy once rather than deleting it outright; it
            # is gitignored, and on the desktop it predates the current
            # dms-shell so it is stale rather than precious.
            if [ -e "$2.pre-symlink" ]; then run rm -rf "$2"
            else run mv "$2" "$2.pre-symlink"; fi
            run ln -s "$1" "$2"
          else
            run ln -s "$1" "$2"
          fi
        }
        relink ${pkgs.dms-shell}/share/quickshell/dms/assets       "$clone/assets"
        relink ${pkgs.dms-shell}/share/quickshell/dms/translations "$clone/translations"
      fi
    '';

  # Same stamp on activation, so `nrs` fixes up a freshly-pulled settings.json
  # without waiting for the next login. DMS watches the file and picks it up.
  home.activation.dmsHostSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${dmsHostSettings}
    '';

  # (chatmix-setup service retired — the chatmixd daemon (flake input) creates
  # the Game/Chat sinks itself on first dial input; the old ~/.local/bin script
  # was never copied and the unit failed every boot.)

  # (wallpaper-rotate script + timer retired — DMS draws + cycles wallpaper now)

  # (hyproled OLED burn-in units moved to hosts/desktop/home.nix — the OLED is
  # DP-3 on the desktop; the laptop panel is IPS.)
}
