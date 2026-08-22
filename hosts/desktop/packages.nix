# Packages bound to THIS box's hardware. Split out of modules/packages.nix so
# the laptop does not carry them: they all build fine on any machine, they just
# have nothing to talk to there.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # RGB / peripherals — OpenRGB controllers, Razer devices, the SteelSeries
    # headset (headsetcontrol), nvidia telemetry.
    openrgb polychromatic headsetcontrol gpustat

    # VR — see vr.nix. wayvr/xrizer are the OpenXR overlay bits.
    wayvr xrizer

    # Gaming launchers that only make sense next to the Steam library.
    umu-launcher bs-manager

    # Phone-as-webcam; vendor .deb repack (Qt5 → libsForQt5 scope for
    # qtbase/qtwayland/wrapQtAppsHook). Needs the v4l2loopback module, which is
    # loaded in system-tweaks.nix — desktop-only, so the package follows it.
    (libsForQt5.callPackage ../../pkgs/iriunwebcam.nix { })
  ];
}
