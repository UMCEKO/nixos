# HP EliteBook 6 G1a — Ryzen AI 7 350 (Krackan Point: Zen 5 + Zen 5c,
# Radeon 860M / RDNA 3.5), 32 GB, 512 GB NVMe, 14" WUXGA (1920x1200).
#
# nixos-hardware has NO profile for this machine: HP dropped the 3-digit model
# numbers this generation ("EliteBook 6/8/X"), and the repo only carries
# hp/elitebook/{2560p,830,845}. That is fine — the closest AMD analogue,
# 845/g8, is almost nothing but a wrapper around the same generic modules we
# import below, so we lose nothing by importing them directly.
{ config, lib, pkgs, inputs, ... }:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-cpu-amd-pstate  # amd_pstate=active on kernel >=6.3 — the EPP driver
    common-gpu-amd         # sets videoDrivers = [ "amdgpu" ]
    common-pc-laptop
    common-pc-ssd
  ];

  # Krackan Point is recent silicon; the iGPU wants current firmware. If wifi
  # turns out to need a redistributable-but-unfree blob, promote this to
  # hardware.enableAllFirmware.
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # NOT set: amdgpu.sg_display=0. The 845/g8 profile carries it for a
  # white-screen-after-display-reconfigure bug, but that is a Cezanne-era
  # workaround and blindly applying old GPU quirks is how you inherit someone
  # else's bug. If the panel goes white after hotplugging an external monitor,
  # this is the first thing to try:
  #   boot.kernelParams = [ "amdgpu.sg_display=0" ];

  # Power management. power-profiles-daemon (pulled in by common-pc-laptop) and
  # TLP are mutually exclusive — enabling both gives you two daemons fighting
  # over the same sysfs knobs. ppd is the one that integrates with the KDE and
  # DMS battery applets, so it wins; do not add TLP without removing this.
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # Wi-Fi power save OFF. NetworkManager's default parks the radio between
  # beacons on battery, and the AP then buffers your traffic until the next
  # wake — which is invisible for a download and miserable for anything
  # interactive. Measured here on an idle link with a -40 dBm signal, 0%
  # loss and 0 tx failures, pinging the FIRST HOP:
  #
  #   power save on:   rtt min/avg/max/mdev = 2.1/63.3/452.1/126.9 ms
  #   power save off:  rtt min/avg/max/mdev = 2.2/6.3/23.8/4.7 ms
  #
  # End to end over SSH that was the difference between a 950 ms average
  # with 2.2 s spikes and a 28 ms average. Nothing was wrong with the link,
  # the remote host, or sshd — the packets were asleep.
  #
  # The cost is battery: the radio no longer naps. If you ever want it back
  # for a long flight, this is one line, and `iw dev wlp195s0 get power_save`
  # tells you which state you are in.
  networking.networkmanager.wifi.powersave = false;

  # MT7925 PCIe ASPM off. The card is allowed into L1.2 deep sleep
  # (LnkCtl: ASPM L1 Enabled, L1SubCtl1: ASPM_L1.2+), and waking it stalls
  # packet delivery for seconds at a time. This is SEPARATE from the 802.11
  # power save above and is not fixed by turning that off — the giveaway is
  # that delayed pings come back in a burst with a descending ladder of RTTs
  # (2418, 2210, 2002, 1794 ... each step one ping interval) rather than being
  # dropped. They were queued, not lost.
  #
  # mt7925e ships exactly one module parameter and it is this one, which is a
  # fair signal that the hardware's ASPM implementation is not trusted.
  #
  # Measured on the FIRST HOP, 750 packets over 150 s, 5 GHz, 0% loss:
  #
  #   ASPM on:   rtt min/avg/max/mdev = 1.9/154.3/2418.4/418.5 ms
  #   ASPM off:  rtt min/avg/max/mdev = 1.2/  4.3/  81.5/  6.3 ms
  #                                     78% under 5 ms, nothing over 100 ms
  #
  # Costs a little idle power, like the power save line above.
  boot.extraModprobeConfig = ''
    options mt7925e disable_aspm=1
    options cfg80211 ieee80211_regdom=US
  '';

  # Wi-Fi regulatory domain forced to US.
  #
  # Not where this machine is — the point is which channels the card is
  # willing to see. Turkey follows ETSI, which prohibits UNII-3 (channels
  # 149-165), and Android phone hotspots on "5 GHz" almost always land on
  # channel 149. The card would not scan there, so the phone's hotspot was
  # invisible here while every other device found it instantly.
  #
  # The regdomain was not configured anywhere: it came from the ASSOCIATED AP's
  # 802.11d country IE (`iw dev wlp195s0 scan dump | grep Country:` ->
  # "Country: TR Environment: bogus"). Attach to an AP that advertises TR and
  # the kernel adopts TR, along with its channel restrictions.
  #
  # The modprobe line sets the domain when cfg80211 loads; the service below
  # re-asserts it as a USER hint, which is the part that matters. Verified that
  # a user hint is NOT overridden by the country IE: set US, disconnected,
  # reconnected to the TR-advertising AP, and the domain stayed US with 5745
  # MHz still listed at 30 dBm.
  #
  # Tradeoff: US forbids 2.4 GHz channels 12-13, which ETSI allows. Almost
  # nothing uses them; if you ever meet an AP that does, that is this line.
  systemd.services.wifi-regdom = {
    description = "Set the Wi-Fi regulatory domain";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iw}/bin/iw reg set US";
    };
  };

  # Lid/suspend. AMD laptops of this generation are s2idle-only (no S3), which
  # is also why suspend battery drain is the recurring complaint on them.
  # Verify what the firmware actually offers before debugging any of it:
  #   cat /sys/power/mem_sleep
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Backlight: brightnessctl (already in modules/packages.nix) ships udev rules
  # granting the `video` group write access to the backlight sysfs, and umceko
  # is in `video` via modules/common.nix — so no extra module is needed.
  # NOT programs.light: removed from nixpkgs (unmaintained upstream); the
  # option now hard-asserts rather than warning.

  # TRIM through to the SSD. common-pc-ssd (above) enables fstrim.timer, but a
  # dm-crypt mapping drops every discard it is not explicitly told to pass on —
  # so without this the weekly fstrim runs, reports success and trims nothing
  # (`sudo dmsetup table cryptroot` shows no allow_discards; `fstrim -v /`
  # reports 0 B). The placeholder hardware-configuration.nix set this; the real
  # nixos-generate-config scan that replaced it does not emit it, which is why
  # it lives here instead — that file is generated and says not to edit it.
  #
  # The tradeoff is the usual one for encrypted SSDs: discards leak which
  # blocks are unused, i.e. a rough picture of how full the disk is. Standard
  # for a laptop; if you ever decide the leak matters more than the drive's
  # write amplification, this is the line to remove.
  boot.initrd.luks.devices."cryptroot".allowDiscards = true;

  # Firmware updates. HP business laptops are well covered by LVFS.
  services.fwupd.enable = true;

  # No fingerprint reader on this unit. This is settled — do not re-investigate:
  #   - nothing on USB, and no SPI bus exists at all (/sys/class/spi_master
  #     is empty), so there is no bus for one to hide on
  #   - no biometric ACPI node. The only Synaptics part is SYNA3143 at
  #     \_SB_.I2CA.TPAD — that is the touchpad (06CB:D004 via i2c_hid_acpi)
  #   - hp_bioscfg exposes 268 BIOS attributes, with per-device toggles for
  #     camera / microphone / Bluetooth / WLAN / storage, and NO fingerprint
  #     entry among them. HP does not ship a toggle for hardware that is absent.
  # On this generation the reader lives in the POWER BUTTON, not the palm rest,
  # and it is configure-to-order. SKU D36SZET#AB8 was ordered without it.
  #
  # The small square with the wave emblem on the palm rest is the NFC
  # touchpoint, not a sensor: NXP8013 at \_SB_.I2CB.NPC2, from HP's AMDNFCI2
  # SSDT. Unusable here in any case — its _STA reads 0 (not fitted, the same
  # marker the absent ELAN2513 touchscreen carries, while the fitted touchpad
  # reads 15), and the in-tree nxp-nci_i2c driver only matches NXP1001 /
  # NXP1002 / NXP7471 anyway.
  #
  # 'Enhanced Sign-In Security' in hp_bioscfg is a red herring: it is present
  # on every HP business SKU, is not in this machine's F10 menu, and the
  # firmware rejects WMI writes to it (hp_bioscfg: error 0x4, "Invalid command
  # type"). It is not hiding a sensor.
  #
  # What this machine does have is an IR camera — see face-unlock.nix.

  # Bluetooth — the desktop gets this from peripherals.nix, which is
  # desktop-only (it also carries Wooting/Razer/OpenRGB).
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
