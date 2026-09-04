# Base system config shared by every host.
#
# The rule for this file: if it would be equally true on a laptop in a cafe as
# on the desktop, it belongs here. Anything tied to specific silicon (nvidia,
# the 7900X wake-fault mitigations, the igc NIC), to a specific role (exit
# node, nginx vhosts) or to specific peripherals lives under hosts/<name>/.
{ config, pkgs, lib, inputs, ... }:

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

  # CUDA pkgs are unfree, so Hydra never builds them and cache.nixos.org has nothing to serve.
  nix.settings.substituters = [ "https://cuda-maintainers.cachix.org" ];
  nix.settings.trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];

  # http2 OFF, deliberately, despite the upstream default being on.
  #
  # Measured 2026-08-26, `nix copy` of a fixed 400-path / 1.5 GB closure from
  # cache.nixos.org into a scratch store, throughput sampled off eno1:
  #
  #     http2=true   ->  7.99 MB/s  ( 67 Mbit/s)   <- was stuck here
  #     http2=false  -> 19.38 MB/s  (163 Mbit/s)
  #
  # Under HTTP/2 curl multiplexes every request onto ONE connection per host,
  # so http-connections and max-substitution-jobs above collapse onto a single
  # socket and the whole switch runs at exactly single-stream speed (a lone
  # curl stream to the Vienna POP measures 7.8 MB/s -- same number). Forcing
  # HTTP/1.1 makes each substitution job open its own socket.
  #
  # NOT a mirror problem. Substituters were benchmarked cold-vs-cold on six
  # identical NARs before ruling them out; cache.nixos.org won 4 of 6 outright
  # and USTC 404'd on the other two:
  #
  #     cache.nixos.org  3.40 - 7.96 MB/s cold  (36 MB/s once hot)
  #     USTC (CN)        2.48 - 4.61 MB/s, 2 of 6 MISSING
  #     SJTU (CN)        5.27 MB/s        TUNA / NJU: 404 on everything
  #     nix-cache.s3.amazonaws.com: 403
  #
  # No usable mirror exists from TR, and an incomplete one is worse than none:
  # every extra substituter costs a narinfo round-trip PER PATH at ~60ms RTT
  # before Nix falls back. Fastly itself already serves 565 Mbit/s here at 32
  # real sockets, so the bytes were never the constraint.
  #
  # That 3.40 -> 36 MB/s spread on ONE host is Fastly cold-miss vs hot-hit: a
  # cold object makes the Vienna edge pull from the IAD shield. After a nixpkgs
  # bump nearly every path is cold, which is why parallel sockets matter so
  # much here -- they overlap that latency instead of stacking it.
  #
  # Ceiling after this is ~20 MB/s, below the 67 MB/s raw curl reaches. The
  # rest is Nix's own pipeline (closure dependency ordering, narinfo
  # round-trips, store writes), not bandwidth. Raising max-substitution-jobs
  # does NOT help: 16 -> 20.06, 32 -> 19.38, 64 -> 19.17 MB/s, all noise.
  nix.settings.http2 = false;

  # download-buffer-size is deliberately NOT set. The obvious suspect, and it
  # measured neutral: at the default 1 MiB the same copy ran 18.63 MB/s vs
  # 19.38 at 512 MiB, with zero "download buffer is full" warnings in any run.
  # Decompression is not the constraint either -- xz -d benchmarks at 216 MB/s
  # here and the cache is ~90% zstd. Don't reach for these two; it's http2.

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

  # Router SERVFAILs DS/DNSKEY over UDP instead of setting TC, so allow-downgrade still fails shut.
  # Baseline only: hosts/desktop/dns.nix raises this to strict DoT on the fixed line.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = lib.mkDefault "false";
      # Roaming hosts keep opportunistic: a captive portal must be able to answer before login.
      DNSOverTLS = lib.mkDefault "opportunistic";
      FallbackDNS = lib.mkDefault [ "9.9.9.9" ];
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

  # Docker's default pool is 172.16/12, which collided with the netbird nameserver's address; 10.210/16 is clear here.
  virtualisation.docker.daemon.settings.default-address-pools = [
    { base = "10.210.0.0/16"; size = 24; }
  ];

  # Tailscale. Routing features / exit-node advertisement are per-host: only
  # the desktop is an exit node, and a laptop advertising one from a hotel
  # network is actively wrong.
  services.tailscale.enable = true;

  # Set explicitly, never omitted: the module only writes keys into config.json and never unsets them again.
  services.netbird.enable = true;
  services.netbird.clients.default.config = {
    # wt0 registers `~.` + default-route=yes, capturing ALL DNS into a proxy that serves nothing while management is down.
    DisableDNS = true;
    DisableClientRoutes = false;
  };

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
