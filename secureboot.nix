# Secure Boot via lanzaboote — signs the bootloader + kernel with your own sbctl
# keys (in /var/lib/sbctl). Enroll them into firmware once with
#   sudo sbctl enroll-keys --microsoft
# (--microsoft is REQUIRED so Windows' bootloader and the GPU option ROM still
# validate), then switch Secure Boot on in the BIOS. To disable: turn Secure
# Boot off in BIOS; the signed bootloader still boots fine unsigned.
{ pkgs, lib, ... }:
{
  environment.systemPackages = [ pkgs.sbctl ];

  boot.loader.systemd-boot.enable = lib.mkForce false;   # lanzaboote replaces it
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
