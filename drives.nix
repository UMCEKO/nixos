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

  # uid/gid: NTFS has no unix perms of its own.
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/AE5A28BF5A288665";
    fsType = "ntfs-3g";
    options = [ "nofail" "uid=1000" "gid=100" "umask=022" ];
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

  # Old CachyOS root, top-level subvol → /mnt/cachyos/@home, /@, /@log, etc.
  fileSystems."/mnt/cachyos" = {
    device = "/dev/disk/by-uuid/076a5948-e843-4ac3-9693-52998113a537";
    fsType = "btrfs";
    options = [ "nofail" "noatime" "compress=zstd" "subvolid=5" ];
  };
}
