-- Keybindings (de-ML4W'd 2026-05-21)

local mainMod     = "SUPER"
local HYPRSCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- ===== Applications =====
hl.bind(mainMod .. " + RETURN",     exec("alacritty"))
hl.bind(mainMod .. " + B",          exec("brave"))
hl.bind(mainMod .. " + E",          exec("nautilus --new-window"))
hl.bind(mainMod .. " + CTRL + E",   exec("rofi -modi emoji -show emoji"))
hl.bind(mainMod .. " + CTRL + C",   exec("gnome-calculator"))

-- ===== Display zoom =====
hl.bind(mainMod .. " + SHIFT + mouse_down",
  exec("hyprctl keyword cursor:zoom_factor $(awk \"BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep 'float:' | awk '{print $2}') + 0.5}\")"))
hl.bind(mainMod .. " + SHIFT + mouse_up",
  exec("hyprctl keyword cursor:zoom_factor $(awk \"BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep 'float:' | awk '{print $2}') - 0.5}\")"))
hl.bind(mainMod .. " + SHIFT + Z", exec("hyprctl keyword cursor:zoom_factor 0"))

-- ===== Windows =====
hl.bind(mainMod .. " + Q",          hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q",  exec("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"))
hl.bind(mainMod .. " + F",          hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + M",          hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + D",          hl.dsp.window.float({ action = "toggle" }))
-- `workspaceopt allfloat` is deprecated in 0.55+. Iterate the active workspace and toggle each.
hl.bind(mainMod .. " + SHIFT + T", function()
  for _, w in ipairs(hl.get_workspace_windows(hl.get_active_workspace())) do
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
  end
end)
hl.bind(mainMod .. " + J",          hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + K",          hl.dsp.layout("swapsplit"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Mouse drag/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Move window in tile
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "down"  }))

-- Swap with neighbor
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "left"  }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "up"    }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "down"  }))

-- Special workspaces
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special(""))
hl.bind(mainMod .. " + G", hl.dsp.workspace.toggle_special("gtnh"))

-- ===== Actions / utilities =====
hl.bind(mainMod .. " + CTRL + R",   exec("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + A",  exec(HYPRSCRIPTS .. "/toggle-animations.sh"))
hl.bind(mainMod .. " + PRINT",      exec(HYPRSCRIPTS .. "/screenshot.sh"))
hl.bind(mainMod .. " + ALT + F",    exec(HYPRSCRIPTS .. "/screenshot.sh --instant"))
hl.bind(mainMod .. " + SHIFT + S",  exec(HYPRSCRIPTS .. "/screenshot.sh --instant-area --clipboard"))
hl.bind(mainMod .. " + ALT + R",    exec(HYPRSCRIPTS .. "/record-area.sh"))
hl.bind(mainMod .. " + CTRL + Q",   exec(HYPRSCRIPTS .. "/wlogout.sh"))
hl.bind(mainMod .. " + SHIFT + W",  exec("waypaper --random"))
hl.bind(mainMod .. " + CTRL + W",   exec("waypaper"))
hl.bind(mainMod .. " + ALT + W",    exec(HYPRSCRIPTS .. "/wallpaper-automation.sh"))
-- SUPER + space cycles keyboard layouts (us <-> tr)
hl.bind(mainMod .. " + space",      exec("hyprctl switchxkblayout current next"))
-- Tap SUPER (release SUPER_L with no other key pressed) opens the launcher
hl.bind(mainMod .. " + SUPER_L",    exec("pkill rofi || rofi -show drun -replace -i"), { release = true })
-- Macro / code:201 keep the launcher shortcut as a fallback
hl.bind("code:201",                 exec("pkill rofi || rofi -show drun -replace -i"), { ignore_mods = true })
hl.bind(mainMod .. " + CTRL + K",   exec(HYPRSCRIPTS .. "/keybindings.sh"))
hl.bind(mainMod .. " + SHIFT + B",  exec("hyprpanel -q; hyprpanel"))
hl.bind(mainMod .. " + CTRL + B",   exec("hyprpanel -t bar-0"))
hl.bind(mainMod .. " + SHIFT + R",  exec(HYPRSCRIPTS .. "/loadconfig.sh"))
hl.bind(mainMod .. " + V",          exec(HYPRSCRIPTS .. "/cliphist.sh"))
hl.bind(mainMod .. " + CTRL + T",   exec("hyprpanel -t settings-dialog"))
hl.bind(mainMod .. " + ALT + G",    exec(HYPRSCRIPTS .. "/gamemode.sh"))
hl.bind(mainMod .. " + CTRL + L",   exec(HYPRSCRIPTS .. "/power.sh lock"))
hl.bind(mainMod .. " + SHIFT + H",  exec(HYPRSCRIPTS .. "/hyprshade.sh"))
hl.bind("CTRL + Tab",               exec(HYPRSCRIPTS .. "/focus.sh"))
hl.bind(mainMod .. " + P",          exec(HYPRSCRIPTS .. "/switch-monitor.sh"))
hl.bind("XF86Display",              exec(HYPRSCRIPTS .. "/switch-monitor.sh"))

-- ===== Workspaces =====
local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
for _, key in ipairs(keys) do
  local ws = (key == "0") and "10" or key
  hl.bind(mainMod         .. " + " .. key, exec(HYPRSCRIPTS .. "/switch-workspace.sh workspace "       .. ws))
  hl.bind(mainMod .. " + SHIFT + " .. key, exec(HYPRSCRIPTS .. "/switch-workspace.sh movetoworkspace " .. ws))
  hl.bind(mainMod .. " + CTRL + "  .. key, exec(HYPRSCRIPTS .. "/moveTo.sh " .. ws))
end

-- ===== Fn / media keys =====
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl -q s +5%"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -q s 5%-"))
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",         exec("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioPlay",         exec("playerctl play-pause"))
hl.bind("XF86AudioPause",        exec("playerctl pause"))
hl.bind("XF86AudioNext",         exec("playerctl next"))
hl.bind("XF86AudioPrev",         exec("playerctl previous"))
hl.bind("XF86AudioMicMute",      exec("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
hl.bind("XF86Calculator",        exec("gnome-calculator"))

hl.bind("code:238", exec("brightnessctl -d smc::kbd_backlight s +10"))
hl.bind("code:237", exec("brightnessctl -d smc::kbd_backlight s 10-"))
