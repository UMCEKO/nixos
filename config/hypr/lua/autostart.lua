-- Autostart (de-ML4W'd 2026-05-21)

local HYPRSCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
  -- Cursor theme
  hl.exec_cmd("hyprctl setcursor breeze_cursors 24")

  -- System daemons (NixOS: no hardcoded /usr paths)
  hl.exec_cmd("hyprpolkitagent")

  -- Wallpaper: wpaperd (built-in per-monitor random rotation from
  -- ~/Pictures/Wallpapers/anime — replaces waypaper/awww/rotate-timer chain)
  hl.exec_cmd("wpaperd")
  hl.exec_cmd(HYPRSCRIPTS .. "/gtk.sh")

  -- Notifications (waybar has no daemon of its own; hyprpanel is retired,
  -- so swaync is back and unconflicted)
  hl.exec_cmd("swaync")
  hl.exec_cmd("hypridle")
  -- Tray applets: real pop-open menus for network + bluetooth (waybar companions)
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("wl-paste --watch cliphist store")

  -- Cleanup (removes stale ~/.cache/gamemode flag)
  hl.exec_cmd(HYPRSCRIPTS .. "/cleanup.sh")

  -- Bar: waybar (hyprpanel retired 2026-07-08 — caused dbus races + silent
  -- slow init; maintenance-mode upstream)
  hl.exec_cmd(os.getenv("HOME") .. "/.config/waybar/launch.sh")

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
