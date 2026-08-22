# DankMaterialShell — Quickshell desktop shell. Replaces waybar/eww/swaync.
{ ... }:
{
  # Quickshell classifies PipeWire nodes by EXACT media.class match, so virtual
  # sources ("Audio/Source/Virtual" — e.g. HUSH's Maxine mic) fall through as
  # untracked and DMS never lists them in the input picker (Discord/pavucontrol
  # do, via the Pulse API). Treat them as regular audio sources.
  nixpkgs.overlays = [
    (final: prev: {
      quickshell = prev.quickshell.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/services/pipewire/node.cpp \
            --replace-fail 'strcmp(mediaClass, "Audio/Source") == 0' \
              '(strcmp(mediaClass, "Audio/Source") == 0 || strcmp(mediaClass, "Audio/Source/Virtual") == 0)'
        '';
      });
    })
  ];

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
