# Non-default system tweaks recovered from the old CachyOS /etc + /boot.
# (hostname left as-is; DNS/firewall/nginx/user-units are decisions — see MORNING-README.)
{ config, pkgs, lib, inputs, ... }:
{

  boot.kernelParams = [
    "zswap.enabled=0"     # off — using zram
    "loglevel=3"
    "vsyscall=emulate"    # compat for older/anticheat binaries
    "pcie_aspm.policy=performance"  # replaces pcie_aspm=off, which skipped _OSC and LEFT BIOS ASPM on
    "pcie_ports=native"             # take AER/PME/hotplug; BIOS _OSC declines it otherwise
    "mitigations=off"     # CachyOS-style: reclaim CPU, drops Spectre-class mitigations
    "nowatchdog"          # no soft/hard lockup detectors
    # Mitigation RE-ARMED 2026-08-05: the wake fault survived BIOS 3881 —
    # recurrence #11, the classic signature (died seconds after iriunwebcam's
    # launch-time USB enumeration, on a 7-hour-aged boot where devices had
    # long autosuspended; watchdog reset). 3881 lowered the hazard (~64h vs
    # minutes) but didn't fix the silicon. Verdict: 7900X SoC domain — CPU
    # swap is the fix; these two lines are the proven-safe config until then.
    "processor.max_cstate=1"   # no C2/C3 package sleep
    "usbcore.autosuspend=-1"   # never runtime-suspend USB devices
  ];
  boot.plymouth.enable = true;  # boot splash; drop this if it fights nvidia early-KMS

  # Module tweaks.
  boot.blacklistedKernelModules = [ "wacom" ];
  boot.kernelModules = [ "v4l2loopback" "snd-aloop" ];      # Iriun virtual cam + audio loopback (chatmix)
  # Keep >= 0.15.4: 0.15.3 has a UAF race in VIDIOC_S_FMT that wedges the box with zero logs.
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 devices=1 card_label="Iriun Webcam,Iriun Webcam #2,Iriun Webcam #3,Iriun Webcam #4"
  '';

  # NVIDIA + Wayland environment (GBM / GLX vendor / VA-API). Important for your setup.
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # The driver's built-in "No VidMem Reuse" profile lists Hyprland but not niri, whose VRAM use then balloons (niri wiki: Nvidia).
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri.json".text = builtins.toJSON {
    rules = [ { pattern = { feature = "procname"; matches = "niri"; }; profile = "Limit Free Buffer Pool On Wayland Compositors"; } ];
    profiles = [ { name = "Limit Free Buffer Pool On Wayland Compositors"; settings = [ { key = "GLVidHeapReuseRatio"; value = 0; } ]; } ];
  };

  # SDDM on Wayland (nvidia greeter env is set automatically by the nvidia module).
  services.displayManager.sddm.wayland.enable = true;

  # Services that were enabled on the old box.
  services.avahi.enable = true;            # mDNS / *.local discovery
  networking.firewall.allowedUDPPorts = [ 4698 ];  # Iriun phone discovery/stream
  networking.firewall.allowedTCPPorts = [ 25565 ]; # Minecraft server
  virtualisation.libvirtd.enable = true;   # VMs via virt-manager
  # ollama is installed imperatively, not here: ollama-cuda is in no binary cache and rebuilt on every nixpkgs bump.
  services.openssh.enable = true;          # sshd (auto-opens firewall port 22)
  services.ananicy = {                     # CachyOS auto-nice daemon
    enable = true;
    package = pkgs.ananicy-cpp;            # the cpp rewrite CachyOS ships
    rulesProvider = pkgs.ananicy-rules-cachyos;  # CachyOS's own rules pack
    # Moving realtime Hyprland to the root cgroup cuts it off from the login session, so logind refuses Ctrl+Alt+Fn.
    settings.cgroup_realtime_workaround = lib.mkForce false;
  };
  services.irqbalance.enable = true;       # spread IRQs across cores (CachyOS default)
  services.mullvad-vpn.enable = true;      # NOTE: you also run tailscale — watch for routing conflicts
  services.flatpak.enable = true;          # remote + apps are manual (see MORNING-README)

  # Enable USB wakeup on the Wooting hub (hardware tweak, merges with peripherals.nix rules).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="05e3", ATTRS{idProduct}=="0610", ATTR{power/wakeup}="enabled"

    # Wake-fault mitigation (re-armed 2026-08-05): pin xHCI/GPU/HDA runtime PM.
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x030000", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x040300", ATTR{power/control}="on"
  '';

  # ── Gaming / performance (CachyOS parity) ──────────────────────────────
  powerManagement.cpuFreqGovernor = "performance";        # pin max clocks
  zramSwap = { enable = true; memoryPercent = 50; };      # ~15G compressed swap

  # ── Memory-pressure safety net (2026-08-02) ────────────────────────────
  # Freeze post-mortem: a nixos-rebuild alongside Brave/Discord/Steam/Claude
  # filled all 32G of RAM *and* all 15.9G of zram ("Free swap = 0kB"), so the
  # kernel sat in reclaim thrash — I/O pressure full ~48%, i.e. half of all
  # wall-clock time every task on the box was stalled — until the last-resort
  # OOM killer fired ~60s later. systemd-oomd was active the whole time but
  # every slice reported ManagedOOMSwap=auto (= supervised nothing), because
  # enableUserSlices defaults to false. This makes it actually do its job:
  # one app dies in ~2s instead of the desktop hanging for a minute.
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;   # ManagedOOMSwap=kill on -.slice: acts on swap
                              # exhaustion itself, the exact failure above
    enableUserSlices = true;  # memory-pressure kills among desktop apps
  };
  # system.slice left unmanaged on purpose — oomd there could kill sshd /
  # libvirtd VMs / nginx. nix build memory is capped by policy instead
  # (nix.settings.max-jobs in configuration.nix).

  # Second swap tier on the NVMe root, priority below zram's 5 → only touched
  # once zram is full. zram alone is a cliff, not a cushion: it's compressed
  # RAM, so when it fills there is nowhere left to spill and you OOM on the
  # spot. 814G free on ext4, so a 32G file is noise.
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;   # MB
    priority = 1;       # < zramSwap's default priority of 5
  }];
  # sched-ext gaming scheduler. scx 1.1.3 stalled tasks 32-45s (sched-ext/scx#3750); if 30s+ freezes return, pin back to 1.1.2.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    package = pkgs.scx.full;
  };
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;    # big / Proton / anticheat games
    "vm.swappiness" = 100;              # zram is fast, favor it
    "vm.page-cluster" = 0;              # zram: one page per swapin
    "vm.vfs_cache_pressure" = 50;
    "kernel.split_lock_mitigate" = 0;   # games that trip split-lock
    "net.core.default_qdisc" = "cake";  # bufferbloat for online play
    "net.ipv4.tcp_congestion_control" = "bbr";
    "kernel.hung_task_timeout_secs" = 0;  # no hung-task detector
  };

  # Hardware workaround: your Intel 2.5GbE (igc) NIC drops after suspend — reload on resume.
  systemd.services.igc-resume = {
    description = "Reload igc module after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe -r igc ; ${pkgs.kmod}/bin/modprobe igc";
    };
  };
}
