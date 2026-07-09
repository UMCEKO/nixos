# DankMaterialShell — Quickshell desktop shell. Replaces waybar/eww/swaync.
{ ... }:
{
  programs.dms-shell = {
    enable = true;
    # KDE-gating: the module's dms.service is wantedBy=graphical-session.target,
    # which KDE starts too → DMS would leak into Plasma. Off; launched from
    # hypr/lua/autostart.lua so it only runs under Hyprland.
    systemd.enable = false;

    enableDynamicTheming = true;   # matugen
    enableCalendarEvents = true;   # khal
    enableSystemMonitoring = true; # dgop
    enableAudioWavelength = true;  # cava
    enableClipboardPaste = true;   # wtype
    enableVPN = false;
  };
  programs.dsearch.enable = true;

  # The packaged dms.service is also masked at the user level (it ships with
  # Requisite=graphical-session.target → journal spam under UWSM, Plasma leak
  # under KDE). If a rebuild clears it: systemctl --user mask dms.service
}
