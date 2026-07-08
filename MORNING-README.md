# CachyOS → NixOS port — morning review

Built while you slept. **Nothing has been applied.** Your running system is untouched.
Everything below is staged in `~/nixos` and passes `nixos-rebuild dry-build` (full
evaluation, all packages resolve) with **no errors or warnings**.

---

## TL;DR — how to actually turn it on

Do it in this order (safest → committal):

```bash
cd ~/nixos

# 1. Full build WITHOUT activating (downloads/builds everything, changes nothing).
#    This is big — many GB of Steam/Proton/KDE/Hyprland/etc. Grab coffee.
sudo nixos-rebuild build --flake ~/nixos#nixos

# 2. Activate for THIS boot only (not the default) — try it live, nothing permanent.
sudo nixos-rebuild test --flake ~/nixos#nixos

# 3. If happy, make it the default boot entry.
sudo nixos-rebuild switch --flake ~/nixos#nixos

# Commit the config once you like it:
git -C ~/nixos commit -m "port CachyOS setup: packages, gaming, hyprland, vr, dotfiles"
```

**Rollback anytime:** pick a previous generation in the systemd-boot menu, or
`sudo nixos-rebuild switch --rollback`. Your config history is in git too.

---

## What each file does

| File | Contents |
|------|----------|
| `configuration.nix` | Base system (unchanged parts) + imports the modules below + zsh login shell + docker + permits the EOL electron |
| `packages.nix` | ~150 confirmed-in-nixpkgs apps/CLI/dev/wayland tools from your 469 explicit pkgs |
| `gaming.nix` | `programs.steam` (+gamescope session), gamemode, gamescope, 32-bit graphics, ProtonGE, mangohud, lutris, heroic, prismlauncher, r2modman |
| `desktop.nix` | `programs.hyprland` (your lua config runs on top), xdg portals, fonts, Qt/Kvantum theming — **alongside** your existing KDE Plasma 6 |
| `peripherals.nix` | bluetooth, OpenTabletDriver, OpenRazer, OpenRGB, Wooting udev rule, fwupd |
| `vr.nix` | `services.wivrn` (from stock nixpkgs) + alvr package |
| `home.nix` | home-manager: symlinks your dotfiles + git + zsh wiring |

---

## Decisions I made for you (so I didn't have to wake you)

1. **Dotfiles = live symlinks, not copied into the store.** `home.nix` uses
   `mkOutOfStoreSymlink` to link `~/.config/<x>` → `~/dotfiles/config/<x>`. So you
   keep editing configs in place and `git push` from `~/dotfiles` exactly like on
   CachyOS. I **cloned** `github.com/umceko/dotfiles` to `~/dotfiles` already.
   - Linked: hypr, waybar, rofi, wlogout, swaync, waypaper, nwg-dock, kitty, nvim,
     vim, fish, ohmyposh, fastfetch, matugen, sidepad, Iriun, Kvantum, zshrc, and
     your KDE settings (shortcuts, kdeglobals, kwinrc, panel layout, konsole, kate…).
   - **ML4W skipped** per your instruction — only the lua Hyprland config is wired.
2. **zsh is your login shell again** (was bash on the fresh NixOS install).
3. **Gaming uses NixOS modules** (`programs.steam` etc.) instead of loose packages —
   this is the correct/robust way and replaces `cachyos-gaming-meta`.
4. **VR is minimal** — `services.wivrn` + `alvr` only (see "What's left").
5. **Dropped** all CachyOS/Arch-specific cruft (kernel, mkinitcpio, grub, pacman,
   yay, cachyos-*, znver4 mirrors) — NixOS handles those declaratively.
6. **Security:** permitted `electron-39.8.10` (an installed app bundles an EOL
   Electron). Dropped `ventoy-full` (also flagged insecure) rather than permit it.

---

## What's LEFT for you (the parts that need a human)

### 1. Packages not in nixpkgs (were AUR/vendor) — decide per item
These are **not** in the config yet. Options: find a flake, package yourself, or drop.
```
curseforge, bs-manager, nordpass, reqable, iriunwebcam, antigravity-cli,
win11-clipboard-history, wallpaper-engine-kde-plugin, chatmixd, char-white (cursor)
```
Some have easy answers: NordPass → use `bitwarden`/`keepassxc` (already installed),
CurseForge/bs-manager → `prismlauncher`/`r2modman` (already installed) cover most modding.

### 2. Full VR stack
`wivrn` + `alvr` work from nixpkgs. But `wayvr`, `xrizer`, `xrgears`, monado
extras, opencomposite were AUR/git. The clean route is the **nixpkgs-xr** flake:
`github.com/nix-community/nixpkgs-xr`. Adding it means a new flake input — a real
decision I left for you. Say the word and I'll wire it in.

### 3. KDE settings — symlinked, but consider plasma-manager
I symlinked your KDE rc files so your shortcuts/theme carry over. For a *fully
declarative* KDE you'd use the `plasma-manager` home-manager module. Optional.

### 4. Shell config sanity-check
`~/.zshrc` now sources `~/.config/zshrc` (your dotfile). If your zsh config
references Arch paths or plugins (e.g. `zsh-fast-syntax-highlighting` from a system
path), tweak those — nix puts things in different locations.

### 5. znver4 optimization — NOT reproduced
CachyOS shipped `-march=znver4` builds. Stock nixpkgs is generic x86-64. Matching it
needs a global rebuild overlay (`nixpkgs.hostPlatform.gccarch`) — heavy, rarely worth
it. Left off intentionally.

---

## Reference
- Full 469-package explicit list (name + version):
  `/tmp/claude-1000/.../scratchpad/explicit.txt`
- Old CachyOS root is still mounted read-only at `/mnt/cachy`
  (unmount with `sudo umount /mnt/cachy` when done).
- Package mapping details are in my chat report from last night.

Ping me when you're up and we'll apply it together and knock out the "what's left" items.
