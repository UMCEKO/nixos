# Peripherals / hardware daemons — the CachyOS equivalents were loose
# packages + manually-enabled services + udev rules. NixOS has modules.
{ pkgs, ... }:
{
  # Bluetooth (you had bluez/bluedevil).
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Drawing tablet (OpenTabletDriver) — installs pkg + udev rules + user service.
  hardware.opentabletdriver.enable = true;

  # Razer peripherals (openrazer + polychromatic GUI).
  hardware.openrazer.enable = true;
  hardware.openrazer.users = [ "umceko" ];

  # OpenRGB (RGB control) — provides udev rules + the openrgb service.
  services.hardware.openrgb.enable = true;

  # SteelSeries Arctis (headsetcontrol) — udev rules so battery reads work unprivileged.
  services.udev.packages = [ pkgs.headsetcontrol ];

  # Wooting keyboards — pulls wooting-udev-rules (uaccess on both hidraw and usb,
  # incl. the One/Two update-mode product IDs) plus wootility. Replaces the
  # hand-written rules, which were hidraw-only and matched all of vendor 03eb
  # (Atmel), not just the two Wooting boards using it.
  hardware.wooting.enable = true;

  # fwupd for firmware updates (you had fwupd).
  services.fwupd.enable = true;
}
