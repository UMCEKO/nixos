# DankMaterialShell — Quickshell desktop shell (bar, control center, notifications,
# launcher, lock, calendar+weather, mpris, clipboard). Replaces the waybar/eww/swaync
# stack (migration in progress; old stack still present until verified).
#
# KDE-gating: systemd.enable = false ON PURPOSE. The module's dms.service is
# `wantedBy = graphical-session.target`, which the KDE/Plasma session ALSO starts —
# that would run DMS inside Plasma (same trap swaync had). Instead we launch DMS from
# Hyprland's autostart.lua (`dms run -d`), which only ever runs in the Hyprland session.
{ ... }:
{
  programs.dms-shell = {
    enable = true;
    systemd.enable = false;        # launched from hypr/lua/autostart.lua instead

    # feature deps (all default true; listed explicitly for clarity)
    enableDynamicTheming = true;   # matugen — wallpaper-driven colors
    enableCalendarEvents = true;   # khal — calendar agenda backend
    enableSystemMonitoring = true; # dgop — cpu/mem/etc widgets
    enableAudioWavelength = true;  # cava — audio visualizer
    enableClipboardPaste = true;   # wtype — paste from clipboard history
    enableVPN = false;             # using mullvad/tailscale, not the NM VPN widget
  };
  programs.dsearch.enable = true;

  # NOTE: the packaged dms.service is masked at the user level
  # (`systemctl --user mask dms.service` → ~/.config/systemd/user/dms.service).
  # Even with systemd.enable = false it stays in the unit search path (ships in
  # the package) with `Requisite=/WantedBy=graphical-session.target`: under UWSM
  # that target is inactive → it fails on every poke (journal spam); under KDE
  # it's active → the shell would leak into Plasma. The mask kills both. DMS runs
  # from Hyprland autostart (`dms run -d`). If a rebuild ever clears the mask,
  # re-run: systemctl --user mask dms.service
}
