# Base system config shared by every host.
#
# The rule for this file: if it would be equally true on a laptop in a cafe as
# on the desktop, it belongs here. Anything tied to specific silicon (nvidia,
# the 7900X wake-fault mitigations, the igc NIC), to a specific role (exit
# node, nginx vhosts) or to specific peripherals lives under hosts/<name>/.
{ config, pkgs, inputs, ... }:

let
  # Default SDDM session: "hyprland" | "hyprland-uwsm" | "plasma". KDE stays
  # installed either way.
  autoSession = "hyprland-uwsm";
in
{
  imports = [
    ./packages.nix
    ./desktop.nix
    ./nvim-lsp.nix
    ./dms.nix
    ./keyring.nix
    ./secureboot.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Faster downloads: many parallel fetches fill a high-latency link (TR -> Fastly).
  nix.settings.http-connections = 128;      # default 25
  nix.settings.max-substitution-jobs = 32;  # default 16 — packages fetched at once
  nix.settings.connect-timeout = 5;         # fail fast on a dead mirror connection

  # NOTE: automatic GC is deliberately NOT set here. It is enabled on the
  # laptop (512 GB) only — turning it on for the desktop would be a behaviour
  # change smuggled in with a refactor. Enable it there when you want it.

  # Mainline latest — has sched_ext, so scx_lavd (the CachyOS scheduler) runs on
  # it. CachyOS kernel via chaotic ABANDONED 2026-07-12: the build blockers were
  # all solved (gnugrep test-suite break → skip doCheck; nvidia-open
  # allowedReferences → null), but nyx-cache rate-limits the kernel/nvidia
  # downloads into oblivion (HTTP 429, ~68s backoff/path). Their infra, not fixable
  # our side. scx_lavd already delivers the scheduler win. See MEMORY.
  #
  # Also what the laptop wants: Krackan Point (Zen 5 + RDNA 3.5) is recent
  # enough that an older kernel means a worse iGPU experience.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Istanbul";
  i18n.defaultLocale = "en_US.UTF-8";
  # All LC_* categories inherit defaultLocale (en_US.UTF-8) — no Turkish, no overrides.

  # X11 kept enabled for XWayland apps; the session itself is Wayland.
  # videoDrivers is per-host (nvidia vs amdgpu).
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  hardware.graphics.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Autologin off so pam has a password to unlock the keyring (see keyring.nix).
  services.displayManager.autoLogin.enable = false;
  services.displayManager.defaultSession = autoSession;

  services.printing.enable = true;
  programs.kdeconnect.enable = true;

  # Sound via pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.sudo = {
    enable = true;
    execWheelOnly = false;
    wheelNeedsPassword = false;
    extraConfig = "#includedir /etc/sudoers.d";
    extraRules = [];
  };

  networking.nameservers = [ "9.9.9.9" ];
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "true";
      DNSOverTLS = "true";
      FallbackDNS = [ "9.9.9.9" ];
    };
  };

  users.users."umceko" = {
    isNormalUser = true;
    description = "Umut Cevdet Kocak";
    extraGroups = [
      "networkmanager" "wheel" "docker" "gamemode"
      "video" "render" "storage" "lp" "scanner" "libvirtd"  # ported from old box
      # DMS opens the evdev devices directly for its keyboard/media handling;
      # without this it logs "insufficient permissions to access input devices"
      # and silently drops those bindings. (`dms setup` does this imperatively —
      # which is exactly the kind of thing that does not survive a reinstall.)
      "input"
    ];
    shell = pkgs.zsh;                    # your CachyOS login shell
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # zsh must be enabled at system level to be a valid login shell.
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;

  # Tailscale. Routing features / exit-node advertisement are per-host: only
  # the desktop is an exit node, and a laptop advertising one from a hotel
  # network is actively wrong.
  services.tailscale.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.backupFileExtension = "hm-bak"; # backup clobbered files instead of failing
  home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];

  programs.firefox.enable = true;
  programs.chromium.extensions = [ "nngceckbapebfimnlniiiahkandclblb" ];

  nixpkgs.config.allowUnfree = true;
  # An installed app bundles an EOL Electron. Permitted so the build passes;
  # see MORNING-README.md (security note) — remove the app to drop this.
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  environment.systemPackages = with pkgs; [
    neovim
    claude-code
    brave
    discord
    zapret
  ];

  # services.zapret lives in hosts/desktop/zapret.nix, NOT here -- this file is
  # shared with the roaming laptop and a TTL tuned for the home TT line is wrong
  # on any other network. The package stays above for `blockcheck` on both.

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "brave";
  };

  # Rebuild shortcut. Derived from the hostname so the same alias does the right
  # thing on both machines — hardcoding #nixos here would have the laptop build
  # the desktop's config, nvidia and all.
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/nixos#${config.networking.hostName}";
  };
}
