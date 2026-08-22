# Desktop: Ryzen 9 7900X + RTX 4090 + AMD iGPU, 32 GiB.
#
# Everything here is true of THIS box and nothing else — the nvidia stack, the
# 7900X SoC wake-fault mitigations, the igc NIC workaround, the exit node, the
# data drives, the nginx vhosts, the SteelSeries dial.
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./gaming.nix
    ./peripherals.nix
    ./vr.nix
    ./drives.nix
    ./system-tweaks.nix
    ./nginx.nix
  ];

  networking.hostName = "nixos";

  # Bootloader. NOTE: secureboot.nix (imported via modules/common.nix) does
  # mkForce false on systemd-boot and hands boot to lanzaboote — this enable is
  # the pre-lanzaboote path, kept so disabling secureboot.nix still boots.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Memtest entry in the boot menu (2026-08-03). The hard lockups leave no
  # kernel trace at all, which is what memory/SoC instability looks like, and
  # the box has no ECC reporting to rule DRAM in or out. Boot it overnight:
  # a single error means stop debugging software.
  boot.loader.systemd-boot.memtest86.enable = true;

  # Memory headroom: max-jobs defaults to `auto` = 24 on this 7900X, and 24
  # concurrent derivations can each take GBs. A rebuild that races the desktop
  # into OOM is what froze the box on 2026-08-02 (see system-tweaks.nix).
  # 8 jobs x 3 cores = 24 threads, same throughput, far smaller peak RSS.
  nix.settings.max-jobs = 8;
  nix.settings.cores = 3;

  # eno1 and wlp8s0 are both on 192.168.0.0/24; wifi wins the route lookup, so
  # strict rpfilter drops every reply arriving on eno1 in mangle PREROUTING.
  networking.firewall.checkReversePath = "loose";

  # NVIDIA. The matching Wayland environment (GBM_BACKEND / __GLX_VENDOR_LIBRARY_NAME
  # / LIBVA_DRIVER_NAME) is in system-tweaks.nix — both are desktop-only, and
  # setting those vars on an AMD machine breaks the session with no useful error.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  # Preserve VRAM across S3 suspend; without it the compositor resumes to black.
  hardware.nvidia.powerManagement.enable = true;

  # SteelSeries ChatMix daemon (module from the chatmixd flake input).
  services.chatmixd.enable = true;

  # This box hosts the exit node → IP forwarding (replaces the old ip_forward
  # sysctl). Re-applied via `tailscale set` on every boot (tailscaled-set.service),
  # so the advertisement survives a state wipe. Approval is in the admin console.
  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.extraSetFlags = [ "--advertise-exit-node" ];

  home-manager.users.umceko.imports = [
    ../../home/common.nix
    ./home.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "26.05";
}
