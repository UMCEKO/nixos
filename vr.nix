# VR — the trickiest part of the port.
#
# In nixpkgs: `wivrn` (with a NixOS module) and `alvr` exist.
# NOT in nixpkgs (were AUR/git): wayvr, xrizer, xrgears, opencomposite bits.
# For the full stack you'll likely want the `nixpkgs-xr` flake overlay:
#   https://github.com/nix-community/nixpkgs-xr
# I've left that as a documented next step (adding a flake input is a
# decision I didn't want to make while you slept). See MORNING-README.md.
#
# What's enabled below is the WiVRn server via its NixOS module — this is
# your primary "wivrn" use-case and works from stock nixpkgs.
{ pkgs, ... }:
{
  services.wivrn = {
    enable = true;
    openFirewall = true;
    # (WiVRn now registers itself as the active OpenXR runtime automatically.)
  };

  # ALVR as an alternative streamer (package only; run manually).
  environment.systemPackages = with pkgs; [
    alvr
    # monado / opencomposite / wayvr / xrizer -> via nixpkgs-xr flake (see README)
  ];
}
