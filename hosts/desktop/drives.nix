# Data drives ported from CachyOS's fstab + udisks auto-mounts. Root lives in
# hardware-configuration.nix; the old CachyOS partition is exposed at /mnt/cachyos.
{ ... }:
{
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/mnt/secondary" = {
    device = "/dev/disk/by-uuid/13cf9875-1537-450d-8c74-08df12531862";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };

  fileSystems."/projects" = {
    device = "/mnt/secondary/projects";
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  # sda1 — CachyOS auto-mounted this via udisks, so it wasn't in the old fstab.
  fileSystems."/mnt/mass-storage" = {
    device = "/dev/disk/by-uuid/d16defd8-27c2-491a-873c-987dde892838";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };
}
