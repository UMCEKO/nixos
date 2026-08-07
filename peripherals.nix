# Peripherals / hardware daemons — the CachyOS equivalents were loose
# packages + manually-enabled services + udev rules. NixOS has modules.
{ pkgs, lib, ... }:
let
  # Wooting Background Service — a Tauri daemon (not part of Wootility) that
  # holds a live link to the keyboard and serves gRPC on 127.0.0.1:50052, which
  # is how Wootility drives app linking (per-app profile switching) and the
  # light indicators (volume/battery/system/Discord) while Wootility is closed.
  #
  # Not in nixpkgs yet — PR #529138 adds the package but no service, so it is
  # inlined here. Drop this whole block for `hardware.wooting.backgroundService`
  # once that (and the follow-up) land.
  wooting-bg-service =
    let
      pname = "wooting-bg-service";
      version = "0.5.0";
      # AppImage only, and the GitHub release repo behind it is private, so this
      # API endpoint is the only public URL. Re-resolve on a version bump:
      #   curl 'https://api.wooting.io/public/bg-service/update-check?target=linux&current_version=0.0.1&arch=x86_64'
      src = pkgs.fetchurl {
        name = "Wooting-Background-Service-${version}-amd64.AppImage";
        url = "https://api.wooting.io/public/bg-service/download-installer?target=linux&arch=x86_64&version=v${version}";
        hash = "sha256-e5NQ9rExdmvobXMEQDfrnU0ofIDOd14AEfH7SkRC6VU=";
      };
      contents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      # No extraPkgs: the AppImage bundles libappindicator3.so.1, which is what
      # the binary dlopens for its tray when libayatana-appindicator3.so.1 is
      # absent, and xdg-open ships in usr/bin.
      extraInstallCommands = ''
        install -Dm444 "${contents}/usr/share/applications/Wooting Background Service.desktop" \
          $out/share/applications/${pname}.desktop

        for size in 32x32 128x128; do
          install -Dm444 ${contents}/usr/share/icons/hicolor/$size/apps/${pname}.png \
            -t $out/share/icons/hicolor/$size/apps
        done
      '';

      meta = {
        description = "Background service for Wooting keyboards (app linking, light indicators)";
        homepage = "https://wooting.io/wootility";
        license = lib.licenses.unfree;
        mainProgram = pname;
        platforms = [ "x86_64-linux" ];
      };
    };
in
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

  # It's a Tauri app with a tray and a webview, so it needs the graphical
  # session — hence a user unit rather than a system service. Do NOT use its own
  # tray "Auto-start" toggle: tauri-plugin-autostart writes a ~/.config/autostart
  # entry pointing at the current /nix/store exe, which dies on the next GC or
  # version bump. Mirrors how hardware.opentabletdriver runs otd-daemon.
  systemd.user.services.wooting-bg-service = {
    description = "Wooting background service (app linking, light indicators)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    unitConfig = {
      After = "graphical-session.target";
      ConditionEnvironment = [ "|WAYLAND_DISPLAY" "|DISPLAY" ];
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe wooting-bg-service;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # fwupd for firmware updates (you had fwupd).
  services.fwupd.enable = true;
}
