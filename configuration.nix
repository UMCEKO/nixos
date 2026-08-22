# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

let
  # Default SDDM session: "hyprland" | "hyprland-uwsm" | "plasma". KDE stays
  # installed either way.
  autoSession = "hyprland-uwsm";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ── Ported CachyOS setup (see MORNING-README.md) ──
      ./packages.nix
      ./gaming.nix
      ./desktop.nix
      ./peripherals.nix
      ./vr.nix
      ./drives.nix
      ./system-tweaks.nix
      ./nginx.nix
      ./nvim-lsp.nix
      ./dms.nix
      ./keyring.nix
      ./secureboot.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Memtest entry in the boot menu (2026-08-03). The hard lockups leave no
  # kernel trace at all, which is what memory/SoC instability looks like, and
  # the box has no ECC reporting to rule DRAM in or out. Boot it overnight:
  # a single error means stop debugging software.
  boot.loader.systemd-boot.memtest86.enable = true;
  programs.kdeconnect.enable = true;
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Faster downloads: many parallel fetches fill a high-latency link (TR -> Fastly).
  nix.settings.http-connections = 128;      # default 25
  nix.settings.max-substitution-jobs = 32;  # default 16 — packages fetched at once
  nix.settings.connect-timeout = 5;         # fail fast on a dead mirror connection
  # Memory headroom: max-jobs defaults to `auto` = 24 on this 7900X, and 24
  # concurrent derivations can each take GBs. A rebuild that races the desktop
  # into OOM is what froze the box on 2026-08-02 (see system-tweaks.nix).
  # 8 jobs x 3 cores = 24 threads, same throughput, far smaller peak RSS.
  nix.settings.max-jobs = 8;
  nix.settings.cores = 3;

  # Mainline latest — has sched_ext, so scx_lavd (the CachyOS scheduler) runs on
  # it. CachyOS kernel via chaotic ABANDONED 2026-07-12: the build blockers were
  # all solved (gnugrep test-suite break → skip doCheck; nvidia-open
  # allowedReferences → null), but nyx-cache rate-limits the kernel/nvidia
  # downloads into oblivion (HTTP 429, ~68s backoff/path). Their infra, not fixable
  # our side. scx_lavd already delivers the scheduler win. See MEMORY.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # eno1 and wlp8s0 are both on 192.168.0.0/24; wifi wins the route lookup, so
  # strict rpfilter drops every reply arriving on eno1 in mangle PREROUTING.
  networking.firewall.checkReversePath = "loose";

  # Set your time zone.
  time.timeZone = "Europe/Istanbul";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # All LC_* categories inherit defaultLocale (en_US.UTF-8) — no Turkish, no overrides.

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
    enable = true;
    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
    videoDrivers = [ "nvidia" ];
  };

  hardware = {
    graphics.enable = true;
    nvidia.open = true;
    # Preserve VRAM across S3 suspend; without it the compositor resumes to black.
    nvidia.powerManagement.enable = true;
  };


  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  # Autologin off so pam has a password to unlock the keyring (see keyring.nix).
  services.displayManager.autoLogin.enable = false;
  services.displayManager.defaultSession = autoSession;


  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.sudo = {
    enable = true;
    execWheelOnly = false;
    wheelNeedsPassword = false;
    extraConfig = "#includedir /etc/sudoers.d";
    extraRules = [];
  };
  networking.nameservers = [
    "9.9.9.9"
  ];
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "true";
      DNSOverTLS = "true";
      FallbackDNS = [
        "9.9.9.9"
      ];
    };
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."umceko" = {
    isNormalUser = true;
    description = "Umut Cevdet Kocak";
    extraGroups = [
      "networkmanager" "wheel" "docker" "gamemode"
      "video" "render" "storage" "lp" "scanner" "libvirtd"  # ported from old box
    ];
    shell = pkgs.zsh;                    # your CachyOS login shell
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # zsh must be enabled at system level to be a valid login shell.
  programs.zsh.enable = true;


  # Docker (you used it on CachyOS).
  virtualisation.docker.enable = true;

  # SteelSeries ChatMix daemon (module from the chatmixd flake input).
  services.chatmixd.enable = true;

  # Tailscale (was running on CachyOS). After switching, run `sudo tailscale up`
  # to re-authenticate this node (or restore old identity — see below).
  services.tailscale.enable = true;
  # You host an exit node → enable IP forwarding (replaces the old ip_forward sysctl).
  services.tailscale.useRoutingFeatures = "server";
  # Re-applied via `tailscale set` on every boot (tailscaled-set.service), so the
  # exit-node advertisement survives a state wipe. Approval lives in the admin console.
  services.tailscale.extraSetFlags = [ "--advertise-exit-node" ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.backupFileExtension = "hm-bak"; # backup clobbered files instead of failing
  home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];
  home-manager.users.umceko = import ./home.nix;

  # Install firefox.
  programs.firefox.enable = true;
  programs = {
    chromium = {
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb"
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # An installed app bundles an EOL Electron. Permitted so the build passes;
  # see MORNING-README.md (security note) — remove the app to drop this.
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    claude-code
    brave
    discord
    zapret
  ];

  services.zapret = {
    enable = false;
    params = [
      "--dpi-desync=fake" 
      "--dpi-desync-ttl=4" 
      "--dpi-desync-fooling=md5sig" 
    ];
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "brave";
  };

  # Rebuild shortcut (nrs = nixos-rebuild switch, the common convention).
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
