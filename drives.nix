# Extra data drives, ported from your old CachyOS /etc/fstab + udisks auto-mounts.
# NOTE: this NixOS install has its own root in hardware-configuration.nix. The old
# CachyOS btrfs @/@home/etc. subvolumes are NOT this system's root — but we DO
# expose that whole partition at /mnt/cachyos (top-level subvol) so old files stay
# reachable. The cross-user phirios Steam bind mount was a hack and is dropped.
{ ... }:
{
  # NTFS support (games drive). btrfs is in the kernel by default (cachyos mount).
  boot.supportedFilesystems = [ "ntfs" ];

  # ext4 "secondary" data drive.
  fileSystems."/mnt/secondary" = {
    device = "/dev/disk/by-uuid/13cf9875-1537-450d-8c74-08df12531862";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };

  # NTFS "games" drive (same UUID your old fstab used for /mnt/games).
  # uid/gid so your user can read/write (NTFS has no unix perms of its own).
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/AE5A28BF5A288665";
    fsType = "ntfs-3g";
    options = [ "nofail" "uid=1000" "gid=100" "umask=022" ];
  };

  # Bind mount /projects -> /mnt/secondary/projects (was in your fstab).
  fileSystems."/projects" = {
    device = "/mnt/secondary/projects";
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  # ext4 "mass-storage" drive (sda1). CachyOS auto-mounted this at /mnt/mass-storage
  # via udisks so it was never in the old fstab — this is the entry that went
  # missing on the NixOS port. Holds backups / docker / Users.
  fileSystems."/mnt/mass-storage" = {
    device = "/dev/disk/by-uuid/d16defd8-27c2-491a-873c-987dde892838";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };

  # Old CachyOS root partition (btrfs). Mounted at the top level (subvolid=5) so
  # every subvol is browsable underneath: /mnt/cachyos/@home/umceko, /@, /@log, etc.
  # noatime + zstd match how CachyOS had it. nofail so a missing/changed disk never
  # blocks boot. Read-write on purpose so you can pull files off and eventually wipe it.
  fileSystems."/mnt/cachyos" = {
    device = "/dev/disk/by-uuid/076a5948-e843-4ac3-9693-52998113a537";
    fsType = "btrfs";
    options = [ "nofail" "noatime" "compress=zstd" "subvolid=5" ];
  };
}
