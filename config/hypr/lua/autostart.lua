-- Autostart (de-ML4W'd 2026-05-21)

local HYPRSCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
  -- Cursor theme
  hl.exec_cmd("hyprctl setcursor breeze_cursors 24")

  -- System daemons (NixOS: no hardcoded /usr paths)
  hl.exec_cmd("hyprpolkitagent")

  -- Wallpaper + idle now handled by DMS (draws wallpaper w/ 10-min cycling;
  -- own idle daemon for screen-off/lock). wpaperd + hypridle retired.
  hl.exec_cmd(HYPRSCRIPTS .. "/gtk.sh")
  hl.exec_cmd("wl-paste --watch cliphist store")

  -- Cleanup (removes stale ~/.cache/gamemode flag)
  hl.exec_cmd(HYPRSCRIPTS .. "/cleanup.sh")

  -- Bar + shell: DankMaterialShell (replaces waybar/eww/swaync).
  -- Import the Hyprland env into the systemd user manager so the service can
  -- reach the compositor, then start our own supervised unit (dms-shell.service,
  -- Restart=on-failure). It has no WantedBy, so it only ever runs here (Hyprland),
  -- never in KDE. NOT the packaged dms.service (masked).
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
  hl.exec_cmd("systemctl --user start dms-shell.service")

  -- App autostart. Workspace pinning lives in window_rules.lua (class-based)
  -- so apps that spawn helper windows still land on the right workspace.
  hl.exec_cmd("brave")
  hl.exec_cmd("prismlauncher -l GTNH")
  hl.exec_cmd("steam")
  hl.exec_cmd("discord")

  -- Initial workspace focus
  hl.exec_cmd(HYPRSCRIPTS .. "/switch-workspace.sh workspace 1")

  -- DBus env propagation for portals
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Activate graphical-session.target so xdg-desktop-portal (>=1.22) can start.
  -- systemd refuses D-Bus activation of portals while the session is "inactive".
  -- (Was an exec-once in conf/custom.conf, lost in the .conf->Lua migration.)
  hl.exec_cmd("systemctl --user start hyprland-session.target")
end)
