-- Window rules (de-ML4W'd 2026-05-21)

local function float_centered(name, match_, w, h, opts)
  local rule = {
    name   = name,
    match  = match_,
    float  = true,
    size   = { w, h },
    center = true,
  }
  if opts then for k, v in pairs(opts) do rule[k] = v end end
  hl.window_rule(rule)
end

-- ===== Floating + centered + sized utilities =====
float_centered("pavucontrol",   { class = ".*org.pulseaudio.pavucontrol.*" }, 700, 600, { pin = true })
float_centered("waypaper",      { class = ".*waypaper.*"                  }, 900, 700, { pin = true })
float_centered("blueman",       { class = "blueman-manager"               }, 800, 600 )
float_centered("missioncenter", { class = "io.missioncenter.MissionCenter"}, 900, 600, { pin = true })
float_centered("gnome-calc",    { class = "org.gnome.Calculator"          }, 700, 600 )
float_centered("share-picker",  { class = "hyprland-share-picker"         }, 600, 400, { pin = true })

-- ===== ChatGPT (title-based) =====
hl.window_rule({ name = "chatgpt-float-1", match = { title = "ChatGPT.*" }, float = true })
hl.window_rule({
  name  = "chatgpt-float-2",
  match = { title = ".*chat.openai.com.*" },
  float = true,
  size  = { 500, "50%" },
  move  = { 20, 70 },
})

-- ===== nwg apps =====
hl.window_rule({
  name  = "nwg-look",
  match = { class = "nwg-look" },
  float = true,
  size  = { 700, 600 },
  move  = { "10%", "20%" },
  pin   = true,
})
hl.window_rule({
  name  = "nwg-displays",
  match = { class = "nwg-displays" },
  float = true,
  size  = { 900, 600 },
  move  = { "10%", "20%" },
  pin   = true,
})

-- Mission Center preferences (title-narrowed)
hl.window_rule({
  name   = "missioncenter-prefs",
  match  = { class = "missioncenter", title = "^(Preferences)$" },
  float  = true,
  pin    = true,
  center = true,
})

-- File pickers (xdg-desktop-portal-gtk)
hl.window_rule({
  name   = "filepickers-center",
  match  = { class = "xdg-desktop-portal-gtk", title = "^(Open.*Files?|Save.*Files?|All Files|Save)" },
  float  = true,
  center = true,
})

-- ===== Tile-by-default browsers (defensive) =====
hl.window_rule({ name = "tile-edge",     match = { title = "^(Microsoft-edge)$"  }, tile = true })
hl.window_rule({ name = "tile-brave",    match = { title = "^(Brave-browser)$"   }, tile = true })
hl.window_rule({ name = "tile-chromium", match = { title = "^(Chromium)$"        }, tile = true })

-- Float title-only matches
hl.window_rule({ name = "float-pavu-title", match = { title = "^(pavucontrol)$"          }, float = true })
hl.window_rule({ name = "float-blueman-t",  match = { title = "^(blueman-manager)$"      }, float = true })
hl.window_rule({ name = "float-nmedit",     match = { title = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "float-qalc",       match = { title = "^(qalculate-gtk)$"        }, float = true })

-- Picture-in-Picture
hl.window_rule({
  name  = "pip",
  match = { title = "^(Picture-in-Picture)$" },
  float = true,
  pin   = true,
  move  = { "69.5%", "4%" },
})

-- Idle inhibit for media windows
hl.window_rule({
  name         = "idle-inhibit-fs",
  match        = { class = "[window]" },
  idle_inhibit = "fullscreen",
})

-- Davinci Resolve (xwayland) — disable blur on borders
hl.window_rule({
  name    = "resolve-noblur",
  match   = { class = "^(\\bresolve\\b)$", xwayland = true },
  no_blur = true,
})

-- Gamescope: pin to fullscreen, keep system awake, no decoration FX.
-- Cursor grab is the game's job (Steam launch opts: --force-grab-cursor);
-- this rule just prevents Hyprland from messing with the window.
hl.window_rule({
  name         = "gamescope-fs",
  match        = { class = "^(gamescope)$" },
  fullscreen   = true,
  idle_inhibit = "fullscreen",
  no_blur      = true,
})

-- GTNH → special workspace
hl.window_rule({
  name      = "gtnh-special",
  match     = { class = "^(GT: New Horizons.*)$" },
  workspace = "special:gtnh",
})

-- Workspace pinning for autostarted apps.
-- Class-based so EVERY window the app spawns lands on the right workspace.
-- The old `[workspace N silent]` exec prefixes only attached the first window;
-- helper/updater windows would consume the rule and the real window leaked to ws 1.
hl.window_rule({ name = "brave-ws1",    match = { class = "^(brave-browser)$" },                      workspace = "1 silent"  })
hl.window_rule({ name = "discord-ws11", match = { class = "^(discord)$" },                            workspace = "11 silent" })
hl.window_rule({ name = "steam-ws3",    match = { class = "^(steam)$" },                              workspace = "3 silent"  })
hl.window_rule({ name = "pear-ws12",    match = { class = "^(com\\.github\\.th_ch\\.youtube_music)$" }, workspace = "12 silent" })
