-- Environment variables (from conf/ml4w.conf + conf/custom.conf)

-- XDG / desktop identity
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt
hl.env("QT_QPA_PLATFORM",                  "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",             "qt6ct")
hl.env("QT_QPA_PLATFORMTHEME",             "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",      "1")

-- GDK / GTK
hl.env("GDK_SCALE",      "1")
hl.env("GDK_BACKEND",    "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Cursor sizing
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Electron / Chromium-based apps
hl.env("OZONE_PLATFORM",                "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT",  "wayland")

-- SDL
hl.env("SDL_VIDEODRIVER", "wayland")

-- Dolphin / KService "Open With" fix
-- XDG_MENU_PREFIX is the key — without it kbuildsycoca6 indexes 0 apps
hl.env("XDG_DATA_DIRS",
  "/home/umceko/.local/share/flatpak/exports/share:" ..
  "/var/lib/flatpak/exports/share:" ..
  "/usr/local/share:/usr/share")
hl.env("XDG_MENU_PREFIX", "plasma-")
