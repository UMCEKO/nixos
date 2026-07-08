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

  # Wooting keyboards need a udev rule to be accessible (wootility was AUR;
  # the udev rule is what actually matters and is easy to declare).
  services.udev.extraRules = ''
    # Wooting keyboards
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", TAG+="uaccess"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
  '';

  # fwupd for firmware updates (you had fwupd).
  services.fwupd.enable = true;
}
