# System packages ported from CachyOS explicit-install list (469 pkgs).
# Only packages CONFIRMED to exist in nixpkgs are enabled here.
# Services/programs that have dedicated NixOS modules live in the other
# *.nix files (gaming, desktop, peripherals, vr) — NOT here.
# See MORNING-README.md for the full mapping + the "needs manual attention" list.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # ── CLI / shell tools ──────────────────────────────────────────
    wget curl aria2 rsync pv file tree tmux
    ripgrep fd eza bat zoxide fzf jq yq-go just
    btop htop fastfetch starship nushell
    yt-dlp ncdu duf tokei trash-cli pandoc tesseract
    unzip p7zip unrar sshpass parted net-tools
    # network / diagnostics
    nmap tcpdump mtr traceroute whois ethtool usbutils pciutils dmidecode dnsutils

    # ── Development ────────────────────────────────────────────────
    git neovim vim
    rustup rust-analyzer zig nasm mono uv pyenv
    nodejs python3 go
    gh github-desktop meld
    kubectl kubernetes-helm k9s argocd pulumi
    awscli2 google-cloud-sdk stripe-cli mongosh
    ollama claude-code codex
    android-tools apktool jadx
    typescript-language-server vtsls dioxus-cli
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
    discord vesktop element-desktop slack
    spotify obsidian gparted thunderbird
    bitwarden-desktop keepassxc anydesk rustdesk-flutter
    onlyoffice-desktopeditors figma-linux
    vlc haruna gpu-screen-recorder krita mpv
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
    kopuz                   # goated music player fr
    audacity
    qpwgraph carla          # PipeWire patchbay + LV2/VST host
    openvpn


    # ── Wayland / Hyprland desktop stack ───────────────────────────
    # Bar/popups/notifications/wallpaper/idle all retired → DankMaterialShell:
    # DMS draws the wallpaper itself (10-min cycling) and has its own idle daemon
    # (screen-off 5m / lock 7m). wpaperd + hypridle removed 2026-07-09.
    psmisc libnotify rofi wlogout
    nwg-displays nwg-look
    hyprlock hyprpicker hyprshade hyprsunset
    hyprpolkitagent
    grim slurp satty grimblast wf-recorder wl-clipboard cliphist
    nsxiv gromit-mpx kdotool matugen cava waypipe
    kitty ghostty wayvr xrizer umu-launcher reqable bs-manager
    brightnessctl playerctl

    # ── Theming / fonts helpers ────────────────────────────────────
    kdePackages.qtstyleplugin-kvantum
    adw-gtk3 bibata-cursors pywal papirus-icon-theme

    # ── Hardware / misc utilities ──────────────────────────────────
    openrgb polychromatic headsetcontrol gpustat
    vulkan-tools

    # Phone-as-webcam; vendor .deb repack (Qt5 → libsForQt5 scope for
    # qtbase/qtwayland/wrapQtAppsHook). v4l2loopback lives in system-tweaks.nix.
    (libsForQt5.callPackage ./pkgs/iriunwebcam.nix { })

    # ── NOT in nixpkgs (were AUR / vendor) — handle later, see README:
    # curseforge, bs-manager, nordpass, reqable, antigravity-cli,
    # win11-clipboard-history, wallpaper-engine-kde-plugin, chatmixd,
    # char-white (cursor), wayvr / xrizer / xrgears (VR — see vr.nix)
  ];
}
