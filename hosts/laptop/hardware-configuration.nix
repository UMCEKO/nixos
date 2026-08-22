# PLACEHOLDER — REPLACE AT INSTALL TIME.
#
# This is not a real hardware scan. It exists so `hosts/laptop` evaluates
# before the machine is set up, which lets typos in the rest of the laptop
# config be caught now rather than while sitting in front of a half-installed
# laptop with no browser.
#
# Every UUID below is fake. At install:
#
#   sudo nixos-generate-config --root /mnt
#   cp /mnt/etc/nixos/hardware-configuration.nix \
#      ~/nixos/hosts/laptop/hardware-configuration.nix
#
# then re-add the boot.initrd.luks.devices block (nixos-generate-config emits
# it when installing onto an already-open LUKS container, but check it made it
# — hosts/laptop/default.nix asserts on its presence).
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Encrypted root. The name on the left is what appears at /dev/mapper/<name>.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    allowDiscards = true;   # TRIM through to the SSD; standard for laptops
  };

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0000-0000";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
