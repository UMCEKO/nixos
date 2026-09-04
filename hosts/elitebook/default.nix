# elitebook: HP EliteBook 6 G1a, Ryzen AI 7 350, 32 GB, 512 GB, 14" WUXGA.
#
# Shipped with FreeDOS, so there is no Windows install to preserve and no
# dual-boot to work around.
#
# NOT imported from the desktop, on purpose:
#   gaming.nix / vr.nix   Steam library and VR hardware live on the desktop
#   nginx.nix             the *.umceko.com vhosts are a desktop role
#   drives.nix            those UUIDs do not exist here
#   peripherals.nix       Wooting / Razer / OpenRGB / SteelSeries
#   system-tweaks.nix     7900X wake-fault mitigations, igc NIC reload,
#                         v4l2loopback, nvidia Wayland env, scx_lavd,
#                         performance governor.
#                         Its crash-forensics sysctls and hardware watchdog
#                         are the exception: after two silent wedges on
#                         2026-09-04 those ARE wanted here, so they were
#                         copied into hardware.nix rather than imported —
#                         the watchdog needs a sleep guard on this host that
#                         the desktop has no use for.
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./face-unlock.nix
  ];

  networking.hostName = "elitebook";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 8C/16T (4x Zen 5 + 4x Zen 5c). Same reasoning as the desktop's cap: `auto`
  # would allow 16 concurrent derivations, each potentially GBs, on 32 GB of
  # RAM with no discrete VRAM to fall back on.
  nix.settings.max-jobs = 4;
  nix.settings.cores = 4;

  # 512 GB, so the store cannot be left to grow unattended the way it can on
  # the desktop's multi-terabyte array.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # zram only — no swapfile. A 512 GB laptop SSD is not the place for a 32 GB
  # swap file, and hibernation is not set up.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Same memory-pressure safety net as the desktop, and for the same reason:
  # without enableUserSlices, systemd-oomd supervises nothing and a rebuild
  # racing the desktop into swap exhaustion hangs the machine for a minute
  # instead of killing one app in ~2s.
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # sshd. Key-only, on purpose: this host leaves the building (see the LUKS
  # assertion below) and would otherwise expose a password prompt to whatever
  # hotel/conference network it lands on. The desktop's openssh block in
  # hosts/desktop/system-tweaks.nix is left on the stock defaults — it never
  # moves off the home LAN.
  #
  # openFirewall defaults to true, so port 22 opens with the service.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;  # else PAM still offers a password
      PermitRootLogin = "no";
    };
  };

  # Was hand-placed in ~/.ssh/authorized_keys on 2026-09-03; declared here so
  # it survives a reinstall. The key carries no comment field — it is the one
  # you pasted in from the machine you ssh in from.
  users.users.umceko.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLtEByLC6U6a8/ADf6jXorM8+U2y1UXwGpWI7gm+o5I"
  ];

  # This machine carries the vCD API token, the kubeconfig, the ArgoCD deploy
  # key and Terraform state for Trendruum. It leaves the building. Full-disk
  # encryption is set up by the installer (see README.md); this only asserts
  # that it actually happened, so an unencrypted install fails loudly at build
  # instead of quietly shipping prod credentials out the door.
  assertions = [{
    assertion = config.boot.initrd.luks.devices != {};
    message = ''
      hosts/elitebook: no LUKS device configured.

      This host holds production credentials and leaves the premises, so it
      must be installed onto an encrypted root. Re-run the installer with
      encryption enabled, or if you have deliberately decided otherwise,
      delete this assertion and write down why.
    '';
  }];

  home-manager.users.umceko.imports = [ ../../home/common.nix ];

  # Set to the release you install from — see the comment in
  # hosts/desktop/default.nix. Do not "upgrade" it later.
  system.stateVersion = "26.05";
}
