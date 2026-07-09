# Non-default system tweaks recovered from the old CachyOS /etc + /boot.
# (hostname left as-is; DNS/firewall/nginx/user-units are decisions — see MORNING-README.)
{ config, pkgs, ... }:
{

  boot.kernelParams = [
    "zswap.enabled=0"     # off — using zram
    "loglevel=3"
    "vsyscall=emulate"    # compat for older/anticheat binaries
    "pcie_aspm=off"       # fixes igc/eno1 NIC dropping after resume
    "mitigations=off"     # CachyOS-style: reclaim CPU, drops Spectre-class mitigations
  ];
  boot.plymouth.enable = true;  # boot splash; drop this if it fights nvidia early-KMS

  # Module tweaks.
  boot.blacklistedKernelModules = [ "wacom" ];
  boot.kernelModules = [ "v4l2loopback" "snd-aloop" ];      # Iriun virtual cam + audio loopback (chatmix)
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

  # SDDM on Wayland (nvidia greeter env is set automatically by the nvidia module).
  services.displayManager.sddm.wayland.enable = true;

  # Services that were enabled on the old box.
  services.avahi.enable = true;            # mDNS / *.local discovery
  virtualisation.libvirtd.enable = true;   # VMs via virt-manager
  services.ollama.enable = true;           # local LLM daemon
  services.openssh.enable = true;          # sshd (auto-opens firewall port 22)
  services.ananicy = {                     # CachyOS auto-nice daemon
    enable = true;
    package = pkgs.ananicy-cpp;            # the cpp rewrite CachyOS ships
    rulesProvider = pkgs.ananicy-rules-cachyos;  # CachyOS's own rules pack
  };
  services.irqbalance.enable = true;       # spread IRQs across cores (CachyOS default)
  services.mullvad-vpn.enable = true;      # NOTE: you also run tailscale — watch for routing conflicts
  services.flatpak.enable = true;          # remote + apps are manual (see MORNING-README)

  # Enable USB wakeup on the Wooting hub (hardware tweak, merges with peripherals.nix rules).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="05e3", ATTRS{idProduct}=="0610", ATTR{power/wakeup}="enabled"
  '';

  # ── Gaming / performance (CachyOS parity) ──────────────────────────────
  powerManagement.cpuFreqGovernor = "performance";        # pin max clocks
  zramSwap = { enable = true; memoryPercent = 50; };      # ~15G compressed swap
  services.scx = { enable = true; scheduler = "scx_lavd"; };  # sched-ext gaming scheduler
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;    # big / Proton / anticheat games
    "vm.swappiness" = 100;              # zram is fast, favor it
    "vm.page-cluster" = 0;              # zram: one page per swapin
    "vm.vfs_cache_pressure" = 50;
    "kernel.split_lock_mitigate" = 0;   # games that trip split-lock
    "net.core.default_qdisc" = "cake";  # bufferbloat for online play
    "net.ipv4.tcp_congestion_control" = "bbr";
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
