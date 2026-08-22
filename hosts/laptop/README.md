# laptop — HP EliteBook 6 G1a

Ryzen AI 7 350 (Krackan Point: 4x Zen 5 + 4x Zen 5c, Radeon 860M / RDNA 3.5),
32 GB, 512 GB NVMe, 14" WUXGA 1920x1200, ships with FreeDOS.

All-AMD. There is no nvidia here, which is why `hosts/desktop/system-tweaks.nix`
(and its `GBM_BACKEND=nvidia-drm` block) is not imported — those variables on an
AMD machine break the Wayland session with no useful error.

## Before installing: three things to check from the live ISO

Do these first. Each one changes what the config should say, and all three are
cheaper to check now than to debug later.

```bash
lspci -k | grep -A3 -i net   # MediaTek MT7925 or Qualcomm? decides firmware
cat /sys/power/mem_sleep     # expect s2idle only; no S3 on this generation
lsusb                        # fingerprint reader vendor (see below)
```

If wifi needs a non-redistributable blob, promote
`hardware.enableRedistributableFirmware` to `hardware.enableAllFirmware` in
`hardware.nix`.

**Fingerprint** is deliberately not configured. HP EliteBooks commonly ship
Synaptics or Goodix parts that libfprint does not support, and a half-working
PAM fingerprint stack locks you out of your own machine. Identify the part
first, then add `services.fprintd` if it is actually supported.

## Install

**The root must be encrypted.** This machine carries the vCD API token (which
can delete every vApp and VM in the org), the kubeconfig, the ArgoCD deploy key
and Terraform state. `hosts/laptop/default.nix` asserts that a LUKS device
exists, so an unencrypted install fails at build rather than quietly shipping
prod credentials out of the building. Retrofitting LUKS means a reinstall.

Partition, encrypt, mount, then:

```bash
sudo nixos-generate-config --root /mnt
```

Copy the generated hardware scan over the placeholder:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix \
   ~/nixos/hosts/laptop/hardware-configuration.nix
```

Check the `boot.initrd.luks.devices` block survived the copy — the placeholder
has one, and the assertion will tell you immediately if the real scan does not.

Then clone this repo to the target and install:

```bash
sudo nixos-install --flake /mnt/home/umceko/nixos#laptop
```

`nixos-generate-config` writes a stub `/etc/nixos/configuration.nix`. Ignore
it. On the desktop that stub once caused a bare `nixos-rebuild switch` to build
the stock installer config and kill the live session — same trap applies here.
The system is flake-managed from `~/nixos` only.

## After first boot

```bash
tailscale up                 # this node is NOT an exit node — desktop-only
nrs                          # alias resolves to ~/nixos#laptop via hostname
```

## Secure Boot

Cleanest lanzaboote setup available: no Windows, no dual-boot, no old keys to
clear. `modules/secureboot.nix` is already imported via `modules/common.nix`,
so the bootloader is signed from the first build.

```bash
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft   # HP firmware; keep --microsoft
# then enable Secure Boot in BIOS
bootctl status && sudo sbctl verify
```

Confirm in BIOS that Setup Mode and custom key enrollment are actually
available before planning around this — HP business firmware with Sure Start
can be particular about it.

## Known open questions

- **Suspend drain.** s2idle-only is normal for this generation and is the
  recurring complaint. Measure before changing anything.
- **`amdgpu.sg_display=0`.** The closest nixos-hardware profile
  (`hp/elitebook/845/g8`) carries it for a white-screen-after-display-reconfigure
  bug. It is a Cezanne-era workaround and is NOT applied here. If the panel goes
  white after hotplugging an external monitor, try it first.
- **NPU.** XDNA 2 has a kernel driver (`amdxdna`) but the Ryzen AI userspace
  stack is Windows-first. Treat the "AI" in the model name as marketing.
- **Hyprland monitor config.** `config/hypr` is shared through
  `home/common.nix` and currently describes the desktop's DP-3 (scale 1.5) and
  DP-4 (scale 2). The laptop panel is 1920x1200 at scale 1. Split the monitor
  block per host before relying on the rice here.
