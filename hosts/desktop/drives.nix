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

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/057bff80-885c-4a90-b4f0-96c66220b32a";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };

  # Env outranks cargo config, so this also beats a repo's `rustc-wrapper = ""`.
  environment.variables = {
    RUSTC_WRAPPER = "/run/current-system/sw/bin/sccache";
    SCCACHE_DIR = "/mnt/secondary/sccache";
    SCCACHE_CACHE_SIZE = "100G";
  };

  # sda1 — CachyOS auto-mounted this via udisks, so it wasn't in the old fstab.
  fileSystems."/mnt/mass-storage" = {
    device = "/dev/disk/by-uuid/d16defd8-27c2-491a-873c-987dde892838";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };
}
