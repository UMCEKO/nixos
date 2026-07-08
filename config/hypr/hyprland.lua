-- Hyprland Lua config — migrated from hyprlang .conf files on 2026-05-21.
-- Backup tarball: ~/hypr-backup-pre-lua-20260521-132826.tar.gz
-- To revert: delete this file (~/.config/hypr/hyprland.lua) — Hyprland falls back to hyprland.conf.

-- Make ~/.config/hypr/lua/*.lua findable via require("foo")
do
  local cfg = os.getenv("HOME") .. "/.config/hypr/lua"
  package.path = cfg .. "/?.lua;" .. package.path
end

require("monitors")
require("env")
require("input")
require("look")
require("layout")
require("misc")
require("workspaces")
require("animations")
require("window_rules")
require("layer_rules")
require("binds")
require("autostart")

-- dbus env (was a bare exec-once in hyprland.conf)
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)
