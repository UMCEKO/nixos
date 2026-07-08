# Extra data drives, ported from your old CachyOS /etc/fstab.
# NOTE: the btrfs @/@home/etc. subvolumes from the old fstab are the OLD OS's
# root and are intentionally NOT here — this NixOS install has its own root in
# hardware-configuration.nix. Only your DATA drives + bind mount are ported.
# The cross-user phirios Steam bind mount was a hack and is dropped.
{ ... }:
{
  # NTFS support (for the games drive).
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
}
