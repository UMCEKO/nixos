# System packages ported from CachyOS explicit-install list (469 pkgs).
# Only packages CONFIRMED to exist in nixpkgs are enabled here.
# Services/programs that have dedicated NixOS modules live in the other
# *.nix files (gaming, desktop, peripherals, vr) — NOT here.
# See MORNING-README.md for the full mapping + the "needs manual attention" list.
#
# SHARED BY BOTH HOSTS. Anything bound to desktop hardware (OpenRGB, the
# SteelSeries headset, VR, the nvidia GPU, the Iriun virtual webcam) lives
# in hosts/desktop/packages.nix instead — it would install fine on the laptop
# and simply have nothing to talk to.
{ pkgs, inputs, ... }:
let
  # dontPatchELF leaves prebuilt addons without libstdc++/libxkbcommon rpaths; nixpkgs#569702 only fixed node-pty, sharp/utf-8-validate/xa11y still need this.
  t3code = pkgs.t3code.override {
    t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (old: {
      # T3 Connect (Google sign-in) is compiled out without these; public values copied from the official 0.0.45 build.
      env = (old.env or { }) // {
        T3CODE_RELAY_URL = "https://relay.t3.codes";
        T3CODE_CLERK_PUBLISHABLE_KEY = "pk_live_Y2xlcmsudDMuY29kZXMk";
        T3CODE_CLERK_JWT_TEMPLATE = "t3-relay";
        T3CODE_CLERK_CLI_OAUTH_CLIENT_ID = "hzxSgY2cH10sDU2r";
      };
      postFixup = (old.postFixup or "") + ''
        find "$out"/libexec/t3code -name '*.node' -path '*linux-x64*' -not -path '*musl*' -type f \
          -exec patchelf --add-rpath ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.libxkbcommon ]} {} \;
      '';
    });
  };
in
{
  environment.systemPackages = with pkgs; [
    # ── CLI / shell tools ──────────────────────────────────────────
    wget curl aria2 rsync pv file tree tmux
    ripgrep fd eza bat zoxide fzf jq yq-go just
    btop htop fastfetch starship nushell rclone
    yt-dlp ncdu duf tokei trash-cli pandoc tesseract
    unzip p7zip unrar sshpass parted net-tools wtype
    # network / diagnostics
    nmap tcpdump mtr traceroute whois ethtool usbutils pciutils dmidecode dnsutils

    # ── Development ────────────────────────────────────────────────
    git neovim vim comma opencode 
    rustup zig nasm mono uv pyenv
    nodejs python3 go netbird
    gh github-desktop meld
    kubectl kubernetes-helm k9s argocd pulumi
    awscli2 google-cloud-sdk stripe-cli mongosh
    codex t3code antigravity-acp
    android-tools apktool jadx
    dioxus-cli
    temurin-bin flutter tree-sitter imagemagick
    terraform kubeseal

    # Dev tooling that was cargo-install'd / bun on CachyOS (not in the pacman
    # list the migration ported). protobuf = protoc; postgresql/redis = clients.
    bun protobuf pkg-config cmake mold sccache grpcurl
    sqlx-cli sea-orm-cli cargo-expand cargo-machete cargo-license
    cargo-zigbuild cargo-xwin
    postgresql redis shopify-cli


    # ── Neovim runtime deps (your nvim config's :checkhealth wanted these) ──
    gcc gnumake        # C compiler + make: treesitter parser compilation, hererocks/luarocks
    luarocks lua5_1    # luarocks plugins (lazy.nvim hererocks)
    lazygit            # lazygit integration
    ghostscript        # `gs` — PDF rendering in render-markdown
    tectonic           # LaTeX math rendering (instead of pdflatex)
    mermaid-cli        # `mmdc` — Mermaid diagram rendering
    zed-editor sublime-merge hoppscotch

    # ── GUI apps ───────────────────────────────────────────────────
    brave google-chrome tor-browser            # firefox via programs.firefox
    element-desktop slack telegram-desktop
    inputs.hearth.packages.${pkgs.stdenv.hostPlatform.system}.default   # Hearth, our Vesktop fork, from its own flake
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.default  # ZapFast, native WhatsApp client
    spotify obsidian gparted thunderbird
    bitwarden-desktop keepassxc anydesk rustdesk-flutter
    onlyoffice-desktopeditors figma-linux
    (callPackage ../pkgs/photocraft.nix { })   # PhotoCraft, Rust Photoshop clone (official AppImage)
    (callPackage ../pkgs/kopuz-nightly.nix { }) # Kopuz Nightly (official AppImage); bump version + hash per nightly
    vlc haruna gpu-screen-recorder mpv
    # OBS wrapped with vkcapture: provides `obs-gamecapture` (Finals launch opts)
    (wrapOBS { plugins = with obs-studio-plugins; [ obs-vkcapture obs-multi-rtmp obs-pipewire-audio-capture ]; })
    qdirstat quickemu unetbootin pavucontrol
    stremio-linux-shell     # native (was flatpak); plain `stremio` removed from nixpkgs (Qt5 webengine CVE)
    pulseaudio              # provides `pactl` client (chatmix script needs it)
    # ventoy-full omitted — flagged insecure (EOL); re-add via permittedInsecurePackages if needed
    # KDE apps not already pulled by plasma6
    kdePackages.kdenlive kdePackages.filelight kdePackages.okular kdePackages.kcalc
    nautilus                # file manager from CachyOS (SUPER+E)
    inkscape
    audacity
    qpwgraph carla          # PipeWire patchbay + LV2/VST host
    openvpn
    cemu
    polychromatic           # Razer GUI — both hosts enable hardware.openrazer

    # ── Wayland / Hyprland desktop stack ───────────────────────────
    # Bar/popups/notifications/wallpaper/idle all retired → DankMaterialShell:
    # DMS draws the wallpaper itself (10-min cycling) and has its own idle daemon
    # (screen-off 5m / lock 7m). wpaperd + hypridle removed 2026-07-09.
    psmisc libnotify rofi wlogout
    nwg-displays nwg-look
    hyprlock hyprpicker hyprshade hyprsunset
    hyprpolkitagent
    xwayland-satellite      # niri spawns it on demand for X11 clients
    grim slurp satty grimblast wf-recorder wl-clipboard cliphist
    nsxiv gromit-mpx kdotool matugen cava waypipe
    kitty ghostty reqable
    brightnessctl playerctl

    # ── Theming / fonts helpers ────────────────────────────────────
    kdePackages.qtstyleplugin-kvantum
    # pywal dropped 2026-10-22: nixpkgs 2026-10-20 pywal16 dies in makeWrapper; re-add once that's fixed.
    adw-gtk3 bibata-cursors papirus-icon-theme

    # ── Hardware / misc utilities ──────────────────────────────────
    vulkan-tools
    iw                # wifi link/regdomain inspection: iw dev <if> link, iw reg get

    # libxkbcommon: LWJGL's bundled SDL3 dlopens it for Wayland; without it SDL3 games from Prism can never run as native Wayland clients.
    (prismlauncher.override { additionalLibs = [ libxkbcommon ]; })
    osu-lazer-bin     # official release repack (tracks ppy servers; source build = osu-lazer). Settings live in ~/.local/share/osu/client.realm, not declarative
  ];

  # Ghostty's notify-reload unit races systemd's SIGUSR2-handler check and fails to launch about half the time; wait on the bus name instead.
  systemd.user.services."app-com.mitchellh.ghostty" = {
    overrideStrategy = "asDropin";
    serviceConfig.Type = "dbus";
  };
}
