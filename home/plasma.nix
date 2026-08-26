# KDE Plasma 6, declaratively — the reproducible source of truth for the
# desktop session. Nothing here is read back from ~/.config at rebuild time:
# plasma-manager WRITES these rc files, so a fresh machine comes up identical.
#
# HOW THIS FILE IS MAINTAINED
#   1. Change what you want in System Settings, on any host.
#   2. `nix run github:nix-community/plasma-manager#rc2nix > /tmp/rc.nix`
#   3. Diff /tmp/rc.nix against this file and fold in the lines you MEANT to
#      change. Do not paste it wholesale — rc2nix dumps runtime state too
#      (see "DELIBERATELY NOT CAPTURED" below).
#
# Captured from host `nixos` (the desktop) on 2026-08-25.
#
# THE macOS LOOK
#   The appearance below reproduces the "plasma6-macos 4.2" transformation pack
#   from its two credited upstreams, which are free and packaged in ../pkgs:
#     sumac-theme          Plasma style, Aurorae, Kvantum, colours, icon packs
#     liquidglass-widgets  the macOS plasmoids (weather, clock, calendar, music)
#   The pack's own install.sh is not usable here: it drives apt/dnf/pacman/zypper
#   and installs imperatively into ~/.local/share, which this file would then
#   overwrite on the next rebuild.
#
#   One substitution: 4.2 credits its window-title widget to Liquid Glass, but
#   that project ships no such widget (checked at rev 02b4476). antroids'
#   application-title-bar is used instead — see the top panel below.
#
# DELIBERATELY NOT CAPTURED — rc2nix emits these, they must not be committed:
#   dataFile "kate/anonymous.katesession"  editor session: cursor lines, splitter
#                                          sizes, a URL into ~/.cache. Pure state.
#   kactivitymanagerdrc.activities.<uuid>  activity UUID, regenerated per machine
#   kwinrc.Desktops.Id_1                   virtual-desktop UUID, ditto
#   kwinrc."Tiling/<uuid>/<uuid>"          tile layouts keyed by those UUIDs, so
#                                          they cannot transfer to another host
#   baloofilerc.General.dbVersion          index schema version, owned by baloo
#   dolphinrc.General.ViewPropsTimestamp   timestamp
#   plasmanotifyrc."Applications/*".Seen   "you have seen this app" runtime flag
#   kxkbrc.Layout.*                        superseded by input.keyboard.layouts
#                                          below — declaring both would fight
#
# HOST-SPECIFIC, so they live in hosts/<name>/home.nix rather than here:
#   kwinrc.Xwayland.Scale   1.7 suits the desktop's 4K panels, not a 1920x1200 laptop
#   kwinrulesrc             the "Finals Force Tearing" rule is a desktop gaming rule
{ pkgs, ... }:
let
  # Neither is in nixpkgs; both are plain data repacks. See ../pkgs for why each
  # needs a derivation rather than a bare fetch.
  sumac-theme = pkgs.callPackage ../pkgs/sumac-theme.nix { };
  liquidglass-widgets = pkgs.callPackage ../pkgs/liquidglass-widgets.nix { };

  # Desktop widgets: weather, clock, calendar, now-playing — the set 4.2 adds at
  # install time. There is no plasma-manager option for these (programs.plasma
  # .desktop covers only icons and mouse actions), and writing them into
  # plasma-org.kde.plasma.desktop-appletsrc by hand does not survive either: the
  # panel script DELETES that file before rebuilding the layout. The Plasma
  # scripting API is the supported way in, and priorities 4/5 put these AFTER
  # the panel script (priority 2) that does the wiping.
  #
  # Shared by the two passes below so they can never drift apart. See the
  # comment on the second pass for why this has to run twice.
  #
  # Coordinates are absolute pixels for a 1920x1200 screen, recovered from this
  # host's ItemGeometries-1920x1200 before the rc file was wiped: weather and
  # calendar along the top, clock and now-playing below them.
  #
  # Two things bend these numbers, so they are not free choices:
  #   * y is measured from below the panel — Plasma adds the panel strut (41px
  #     here), so a declared 0 renders at 41.
  #   * the desktop containment refuses to overlap two widgets and slides the
  #     second one away instead. Music sits at 560 rather than the 336 this host
  #     used to have because the calendar above it is 272 tall; at 336 Plasma
  #     shunted it into the middle of the screen.
  # Assigning w.geometry after the fact does NOT work — the containment ignores
  # it. Placement only takes at addWidget() time, which is why correcting a
  # position means removing the widget and adding it again.
  #
  # `config` carries settings that used to live only in the rc file and so died
  # with it — the weather city being the one that actually shows.
  widgetJs = comment: ''
    ${comment}
    // type -> [x, y, width, height]
    var wanted = {
      "com.jaxparrow07.macoswidgets.weather":      [  80,   0, 384, 272],
      "com.jaxparrow07.macoswidgets.calendar":     [1472,   0, 384, 272],
      "com.jaxparrow07.macoswidgets.clock-square": [  96, 336, 160, 160],
      "com.jaxparrow07.macoswidgets.music":        [1360, 560, 480, 320]
    };

    // type -> group -> key -> value, applied after the widget is created.
    var config = {
      "com.jaxparrow07.macoswidgets.weather": {
        "General": { "location": "Istanbul" }
      }
    };

    for (var d of desktops()) {
      for (var type in wanted) {
        // Collect first, then remove — mutating the list while iterating it
        // skips entries, which is how duplicates used to survive.
        var stale = d.widgets().filter(function (w) { return w.type === type; });
        for (var w of stale) { w.remove(); }
      }

      // Containments for screens that no longer exist stay in the rc file
      // forever. Clearing them above is right; adding to them is not — it is
      // what left a second, invisible copy of every widget behind.
      if (typeof d.screen === "number" && d.screen < 0) { continue; }

      for (var type in wanted) {
        var g = wanted[type];
        var w = d.addWidget(type, g[0], g[1], g[2], g[3]);

        var groups = config[type];
        if (!groups) { continue; }
        for (var group in groups) {
          w.currentConfigGroup = [group];
          for (var key in groups[group]) {
            w.writeConfig(key, groups[group][key]);
          }
        }
      }
    }
  '';
in
{
  programs.plasma = {
    enable = true;

    workspace = {
      # Sumac Night, the macOS 12 style set from ../pkgs/sumac-theme.nix.
      #
      # lookAndFeel (org.kde.sumac.desktop) is deliberately NOT set. Applying a
      # global theme rewrites the panel layout, and `panels` below is the source
      # of truth for that — the two would fight, and which one won would depend
      # on script ordering. Setting the pieces individually looks the same and
      # leaves the layout alone.
      theme = "sumac-night-plasma";       # Plasma style (share/plasma/desktoptheme)

      # KDE apps (Dolphin) read text/view colors from kdeglobals [Colors:*], NOT
      # from the Kvantum style — so Kvantum's dark bg + KDE's default light scheme
      # = dark-on-dark. This applies a matching dark scheme so text is readable.
      # Pairs with SumacDoncsugarDark in config/Kvantum/kvantum.kvconfig.
      colorScheme = "SummaculateNight";   # SummaculateNight.colors

      # Sumac's icon pack is inheritance-only — a lone index.theme that resolves
      # to WhiteSur-dark. whitesur-icon-theme in home.packages is what actually
      # supplies the icons; without it everything falls back to hicolor.
      iconTheme = "Sumac-Night";

      cursor = {
        theme = "WhiteSur-cursors";
        size = 24;
      };

      windowDecorations = {
        library = "org.kde.kwin.aurorae";
        # "-small" is the macOS-sized traffic-light button; "-big" is chunkier.
        theme = "__aurorae__svg__sumac-night-blur-small";
      };

      # The user's own picture, not Sumac's. Sumac ships a wallpaper (and
      # ../pkgs/sumac-theme.nix still assembles it) but it was never what this
      # machine actually had on screen — pointing this at ~/Pictures is what
      # stops a rebuild from overwriting the real one.
      wallpaper = "/home/umceko/Pictures/Wallpapers/anime/general/goblin_slayer_1.jpg";
    };

    input.keyboard.layouts = [
      { layout = "us"; displayName = "en"; }   # English Q
      { layout = "tr"; displayName = "tr"; }   # Turkish Q (default variant, not F)
    ];

    # Power management, transcribed from the desktop's powerdevilrc. rc2nix
    # writes a powerdevilrc but does NOT read the existing one, so without this
    # plasma-manager was silently imposing its own defaults instead of what the
    # desktop actually has. Only [AC] exists on the desktop; battery/lowBattery
    # are left unset so Plasma's defaults apply on the laptop.
    powerdevil.AC = {
      powerButtonAction = "sleep";                   # PowerButtonAction=1
      # AutoSuspendAction=0. The desktop's powerdevilrc also carries
      # AutoSuspendIdleTimeoutSec=1800, but that value is inert while the action
      # is "nothing" and plasma-manager asserts against setting the two together,
      # so it is not reproduced. Set autoSuspend.action to bring it back.
      autoSuspend.action = "nothing";
      turnOffDisplay = {
        idleTimeout = 300;                           # TurnOffDisplayIdleTimeoutSec
        idleTimeoutWhenLocked = "immediately";        # ...WhenLockedSec=0
      };
      dimDisplay = {
        enable = true;
        idleTimeout = 120;                           # DimDisplayIdleTimeoutSec
      };
    };

    # Two panels, macOS-style: a thin menu bar flush to the top edge, and a
    # floating content-width dock centred at the bottom. This replaces the single
    # 46px bottom panel the desktop used to carry.
    # `widgets` order IS the on-screen order (it becomes AppletOrder).
    panels = [
      # ── Menu bar ─────────────────────────────────────────────────────────
      {
        location = "top";
        # 25px floating, which is what this machine's top panel actually was
        # before plasma-manager first took the layout over (plasmashellrc had
        # [PlasmaViews][Panel 184][Defaults] thickness=25, floating=1).
        #
        # An earlier note here claimed Plasma 6.7 clamps panel thickness to a
        # 52px floor. That is wrong on this host — 25 is what it was running.
        height = 25;
        floating = true;
        lengthMode = "fill";
        widgets = [
          # Stands in for the  menu: same corner, same "everything is in here"
          # role. Meta / Alt+F1 already open it (see shortcuts below).
          "org.kde.plasma.kickoff"

          # Window title + traffic-light buttons.
          #
          # This is the piece 4.2 credits to a Liquid Glass "Title Menu" widget.
          # That widget does not exist in that project (rev 02b4476 ships clocks,
          # weather, calendar, music and a timer — nothing else), so antroids'
          # application-title-bar stands in: it is in nixpkgs and plasma-manager
          # already has a module for it.
          {
            applicationTitleBar = {
              layout = {
                elements = [
                  "windowCloseButton"
                  "windowMinimizeButton"
                  "windowMaximizeButton"
                  "windowTitle"
                ];
                horizontalAlignment = "left";
                verticalAlignment = "center";
                # With no window focused macOS shows nothing here rather than a
                # row of dead buttons.
                showDisabledElements = "hide";
                spacingBetweenElements = 6;
              };
              windowControlButtons = {
                # Draw the buttons from the Aurorae decoration, so they match the
                # titlebars Sumac paints rather than the icon theme.
                iconSource = "aurorae";
                auroraeTheme = "sumac-night-blur-small";
                buttonsAspectRatio = 100;
                buttonsMargin = 4;
              };
              windowTitle.maximumWidth = 320;
            };
          }

          # The focused app's own menu bar. Apps have to export it over DBus:
          # Qt/KDE and GTK apps do, most Electron ones do not — those just show
          # nothing here, which is the normal limitation of a global menu on KDE.
          "org.kde.plasma.appmenu"

          # Everything after this is pushed to the right half of the bar.
          "org.kde.plasma.panelspacer"

          {
            systemTray.items = {
              # `extra` = explicitly enabled in the tray. Mirrors extraItems= in
              # plasma-org.kde.plasma.desktop-appletsrc. battery/brightness are
              # harmless on the desktop (no battery -> the applet just hides) and
              # are what the laptop needs, so the list stays shared.
              #
              # org.kde.plasma.weather is deliberately gone: the Liquid Glass
              # weather panel below replaces it, and running both would put two
              # weather readouts in the same bar.
              extra = [
                "org.kde.plasma.cameraindicator"
                "org.kde.plasma.devicenotifier"
                "org.kde.plasma.notifications"
                "org.kde.plasma.clipboard"
                "org.kde.plasma.manage-inputmethod"
                "org.kde.plasma.mediacontroller"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.battery"
                "org.kde.plasma.brightness"
                "org.kde.kscreen"
                "org.kde.plasma.volume"
                "org.kde.plasma.keyboardindicator"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.printmanager"
              ];
            };
          }

          # macOS Weather (Panel), from ../pkgs/liquidglass-widgets.nix.
          "com.jaxparrow07.macoswidgets.weatherpanel"

          # macOS puts the date beside the time in the menu bar, no seconds.
          {
            digitalClock = {
              date = {
                enable = true;
                format = "shortDate";
                position = "besideTime";
              };
              time.showSeconds = "never";
            };
          }
        ];
      }

      # ── Dock ─────────────────────────────────────────────────────────────
      {
        location = "bottom";
        floating = true;
        height = 60;
        # "fit" shrinks the panel to its contents; combined with centre alignment
        # that is what makes it read as a dock rather than a full-width taskbar.
        lengthMode = "fit";
        alignment = "center";
        # macOS reveals the dock on approach. Plasma's closest equivalent that
        # still leaves it visible over an empty desktop is dodging windows.
        hiding = "dodgewindows";
        widgets = [
          {
            iconTasks = {
              # Pinned apps, matching the Meta+<key> launch bindings further down.
              launchers = [
                "applications:brave-browser.desktop"
                "applications:com.mitchellh.ghostty.desktop"
                "applications:org.gnome.Nautilus.desktop"
                "applications:discord.desktop"
                "applications:spotify.desktop"
                "applications:org.kde.kcalc.desktop"
              ];
              iconsOnly = true;
              appearance = {
                showTooltips = true;
                highlightWindows = true;
                # Must stay false: `fill` would stretch the task manager to the
                # full screen width and defeat lengthMode = "fit" above.
                fill = false;
              };
            };
          }
        ];
      }
    ];

    # One virtual desktop, one row (kwinrc [Desktops] Number/Rows). The Id_1
    # UUID that rc2nix also emits is intentionally omitted — see header.
    kwin.virtualDesktops = {
      number = 1;
      rows = 1;
    };

    # Traffic lights, on the left, in macOS order: close, minimize, zoom.
    # Plasma's default puts them on the right, which no amount of theming hides
    # — the Aurorae theme only supplies the artwork, not the placement.
    kwin.titlebarButtons = {
      left = [ "close" "minimize" "maximize" ];
      right = [ ];
    };

    shortcuts = {
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Space";
      kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      kmix.decrease_microphone_volume = "Microphone Volume Down";
      kmix.decrease_volume = "Volume Down";
      kmix.decrease_volume_small = "Shift+Volume Down";
      kmix.increase_microphone_volume = "Microphone Volume Up";
      kmix.increase_volume = "Volume Up";
      kmix.increase_volume_small = "Shift+Volume Up";
      kmix.mic_mute = ["Microphone Mute" "Meta+Volume Mute"];
      kmix.mute = "Volume Mute";
      kmix.push_to_talk = [ ];
      ksmserver."Halt Without Confirmation" = [ ];
      ksmserver."Lock Session" = ["Screensaver" "Meta+L" "Meta+Ctrl+L"];
      ksmserver."Log Out" = ["Ctrl+Alt+Del" "Meta+Ctrl+Q"];
      ksmserver."Log Out Without Confirmation" = [ ];
      ksmserver.LogOut = [ ];
      ksmserver.Reboot = [ ];
      ksmserver."Reboot Without Confirmation" = [ ];
      ksmserver."Shut Down" = [ ];
      kwin."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      kwin."Cycle Overview" = [ ];
      kwin."Cycle Overview Opposite" = [ ];
      kwin."Decrease Opacity" = [ ];
      kwin."Edit Tiles" = "Meta+T";
      kwin.Expose = ["Ctrl+F9" "Meta+F9"];
      kwin.ExposeAll = ["Launch (C)" "Ctrl+F10" "Meta+F10"];
      kwin.ExposeClass = ["Ctrl+F7" "Meta+F7"];
      kwin.ExposeClassCurrentDesktop = [ ];
      kwin."Grid View" = "Meta+G";
      kwin."Increase Opacity" = [ ];
      kwin."Kill Window" = ["Meta+Ctrl+Esc" "Meta+Shift+Q"];
      kwin."Move Tablet to Next LogicalOutput" = [ ];
      kwin.MoveMouseToCenter = "Meta+F6";
      kwin.MoveMouseToFocus = "Meta+F5";
      kwin.MoveZoomDown = [ ];
      kwin.MoveZoomLeft = [ ];
      kwin.MoveZoomRight = [ ];
      kwin.MoveZoomUp = [ ];
      kwin.Overview = "Meta+W";
      kwin."Setup Window Shortcut" = [ ];
      kwin."Show Desktop" = "Meta+D";
      kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
      kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
      kwin."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
      kwin."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
      kwin."Switch Window Down" = "Meta+Down";
      kwin."Switch Window Left" = "Meta+Left";
      kwin."Switch Window Right" = "Meta+Right";
      kwin."Switch Window Up" = "Meta+Up";
      kwin."Switch to Desktop 1" = ["Ctrl+F1" "Meta+F1"];
      kwin."Switch to Desktop 10" = [ ];
      kwin."Switch to Desktop 11" = [ ];
      kwin."Switch to Desktop 12" = [ ];
      kwin."Switch to Desktop 13" = [ ];
      kwin."Switch to Desktop 14" = [ ];
      kwin."Switch to Desktop 15" = [ ];
      kwin."Switch to Desktop 16" = [ ];
      kwin."Switch to Desktop 17" = [ ];
      kwin."Switch to Desktop 18" = [ ];
      kwin."Switch to Desktop 19" = [ ];
      kwin."Switch to Desktop 2" = ["Ctrl+F2" "Meta+F2"];
      kwin."Switch to Desktop 20" = [ ];
      kwin."Switch to Desktop 21" = [ ];
      kwin."Switch to Desktop 22" = [ ];
      kwin."Switch to Desktop 23" = [ ];
      kwin."Switch to Desktop 24" = [ ];
      kwin."Switch to Desktop 25" = [ ];
      kwin."Switch to Desktop 3" = ["Ctrl+F3" "Meta+F3"];
      kwin."Switch to Desktop 4" = ["Ctrl+F4" "Meta+F4"];
      kwin."Switch to Desktop 5" = [ ];
      kwin."Switch to Desktop 6" = [ ];
      kwin."Switch to Desktop 7" = [ ];
      kwin."Switch to Desktop 8" = [ ];
      kwin."Switch to Desktop 9" = [ ];
      kwin."Switch to Next Desktop" = [ ];
      kwin."Switch to Next Screen" = [ ];
      kwin."Switch to Previous Desktop" = [ ];
      kwin."Switch to Previous Screen" = [ ];
      kwin."Switch to Screen 0" = [ ];
      kwin."Switch to Screen 1" = [ ];
      kwin."Switch to Screen 2" = [ ];
      kwin."Switch to Screen 3" = [ ];
      kwin."Switch to Screen 4" = [ ];
      kwin."Switch to Screen 5" = [ ];
      kwin."Switch to Screen 6" = [ ];
      kwin."Switch to Screen 7" = [ ];
      kwin."Switch to Screen Above" = [ ];
      kwin."Switch to Screen Below" = [ ];
      kwin."Switch to Screen to the Left" = [ ];
      kwin."Switch to Screen to the Right" = [ ];
      kwin."Toggle Night Color" = [ ];
      kwin."Toggle Window Raise/Lower" = [ ];
      kwin."Walk Through Windows" = ["Alt+Tab" "Meta+Tab" "Ctrl+Tab"];
      kwin."Walk Through Windows (Reverse)" = ["Alt+Shift+Tab" "Meta+Shift+Tab"];
      kwin."Walk Through Windows Alternative" = [ ];
      kwin."Walk Through Windows Alternative (Reverse)" = [ ];
      kwin."Walk Through Windows of Current Application" = ["Alt+`" "Meta+`"];
      kwin."Walk Through Windows of Current Application (Reverse)" = ["Alt+~" "Meta+~"];
      kwin."Walk Through Windows of Current Application Alternative" = [ ];
      kwin."Walk Through Windows of Current Application Alternative (Reverse)" = [ ];
      kwin."Window Above Other Windows" = [ ];
      kwin."Window Below Other Windows" = [ ];
      kwin."Window Close" = ["Alt+F4" "Meta+Q"];
      kwin."Window Custom Quick Tile Bottom" = [ ];
      kwin."Window Custom Quick Tile Left" = [ ];
      kwin."Window Custom Quick Tile Right" = [ ];
      kwin."Window Custom Quick Tile Top" = [ ];
      kwin."Window Fullscreen" = "Meta+F";
      kwin."Window Grow Horizontal" = [ ];
      kwin."Window Grow Vertical" = [ ];
      kwin."Window Lower" = [ ];
      kwin."Window Maximize" = ["Meta+PgUp" "Meta+M"];
      kwin."Window Maximize Horizontal" = [ ];
      kwin."Window Maximize Vertical" = [ ];
      kwin."Window Minimize" = "Meta+PgDown";
      kwin."Window Move" = [ ];
      kwin."Window Move Center" = [ ];
      kwin."Window No Border" = [ ];
      kwin."Window On All Desktops" = [ ];
      kwin."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      kwin."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      kwin."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
      kwin."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
      kwin."Window One Screen Down" = [ ];
      kwin."Window One Screen Up" = [ ];
      kwin."Window One Screen to the Left" = [ ];
      kwin."Window One Screen to the Right" = [ ];
      kwin."Window Operations Menu" = "Alt+F3";
      kwin."Window Pack Down" = [ ];
      kwin."Window Pack Left" = [ ];
      kwin."Window Pack Right" = [ ];
      kwin."Window Pack Up" = [ ];
      kwin."Window Quick Tile Bottom" = "Meta+Shift+Down";
      kwin."Window Quick Tile Bottom Left" = [ ];
      kwin."Window Quick Tile Bottom Right" = [ ];
      kwin."Window Quick Tile Left" = "Meta+Shift+Left";
      kwin."Window Quick Tile Right" = "Meta+Shift+Right";
      kwin."Window Quick Tile Top" = "Meta+Shift+Up";
      kwin."Window Quick Tile Top Left" = [ ];
      kwin."Window Quick Tile Top Right" = [ ];
      kwin."Window Raise" = [ ];
      kwin."Window Resize" = [ ];
      kwin."Window Restore" = "Meta+Backspace";
      kwin."Window Shrink Horizontal" = [ ];
      kwin."Window Shrink Vertical" = [ ];
      kwin."Window to Desktop 1" = [ ];
      kwin."Window to Desktop 10" = [ ];
      kwin."Window to Desktop 11" = [ ];
      kwin."Window to Desktop 12" = [ ];
      kwin."Window to Desktop 13" = [ ];
      kwin."Window to Desktop 14" = [ ];
      kwin."Window to Desktop 15" = [ ];
      kwin."Window to Desktop 16" = [ ];
      kwin."Window to Desktop 17" = [ ];
      kwin."Window to Desktop 18" = [ ];
      kwin."Window to Desktop 19" = [ ];
      kwin."Window to Desktop 2" = [ ];
      kwin."Window to Desktop 20" = [ ];
      kwin."Window to Desktop 21" = [ ];
      kwin."Window to Desktop 22" = [ ];
      kwin."Window to Desktop 23" = [ ];
      kwin."Window to Desktop 24" = [ ];
      kwin."Window to Desktop 25" = [ ];
      kwin."Window to Desktop 3" = [ ];
      kwin."Window to Desktop 4" = [ ];
      kwin."Window to Desktop 5" = [ ];
      kwin."Window to Desktop 6" = [ ];
      kwin."Window to Desktop 7" = [ ];
      kwin."Window to Desktop 8" = [ ];
      kwin."Window to Desktop 9" = [ ];
      kwin."Window to Next Desktop" = [ ];
      kwin."Window to Next Screen" = "Meta+Shift+Right";
      kwin."Window to Previous Desktop" = [ ];
      kwin."Window to Previous Screen" = "Meta+Shift+Left";
      kwin."Window to Screen 0" = [ ];
      kwin."Window to Screen 1" = [ ];
      kwin."Window to Screen 2" = [ ];
      kwin."Window to Screen 3" = [ ];
      kwin."Window to Screen 4" = [ ];
      kwin."Window to Screen 5" = [ ];
      kwin."Window to Screen 6" = [ ];
      kwin."Window to Screen 7" = [ ];
      kwin.disableInputCapture = "Meta+Shift+Esc";
      kwin.view_actual_size = "Meta+0";
      kwin.view_zoom_in = ["Meta++" "Meta+="];
      kwin.view_zoom_out = "Meta+-";
      mediacontrol.mediavolumedown = [ ];
      mediacontrol.mediavolumeup = [ ];
      mediacontrol.nextmedia = "Media Next";
      mediacontrol.pausemedia = "Media Pause";
      mediacontrol.playmedia = [ ];
      mediacontrol.playpausemedia = "Media Play";
      mediacontrol.previousmedia = "Media Previous";
      mediacontrol.seekbackwardmedia = "Media Rewind";
      mediacontrol.seekbackwardmedialong = [ ];
      mediacontrol.seekforwardmedia = "Media Fast Forward";
      mediacontrol.seekforwardmedialong = [ ];
      mediacontrol.stopmedia = "Media Stop";
      org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      org_kde_powerdevil.Hibernate = "Hibernate";
      org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      org_kde_powerdevil.PowerDown = "Power Down";
      org_kde_powerdevil.PowerOff = "Power Off";
      org_kde_powerdevil.Sleep = "Sleep";
      org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      org_kde_powerdevil."Turn Off Screen" = [ ];
      org_kde_powerdevil.powerProfile = ["Battery" "Meta+B"];
      plasmashell."Slideshow Wallpaper Next Image" = [ ];
      plasmashell."activate application launcher" = ["Meta" "Alt+F1"];
      plasmashell."activate task manager entry 1" = "Meta+1";
      plasmashell."activate task manager entry 10" = [ ];
      plasmashell."activate task manager entry 2" = "Meta+2";
      plasmashell."activate task manager entry 3" = "Meta+3";
      plasmashell."activate task manager entry 4" = "Meta+4";
      plasmashell."activate task manager entry 5" = "Meta+5";
      plasmashell."activate task manager entry 6" = "Meta+6";
      plasmashell."activate task manager entry 7" = "Meta+7";
      plasmashell."activate task manager entry 8" = "Meta+8";
      plasmashell."activate task manager entry 9" = "Meta+9";
      plasmashell."clear history" = [ ];
      plasmashell.clear-history = [ ];
      plasmashell.clipboard_action = "Meta+Ctrl+X";
      plasmashell.cycle-panels = "Meta+Alt+P";
      plasmashell.cycleNextAction = [ ];
      plasmashell.cyclePrevAction = [ ];
      plasmashell.edit_clipboard = [ ];
      plasmashell."manage activities" = [ ];   # freed for Window Close (Hyprland SUPER+Q)
      plasmashell."next activity" = "Meta+A";
      plasmashell."previous activity" = "Meta+Shift+A";
      plasmashell.repeat_action = [ ];
      plasmashell."show dashboard" = "Ctrl+F12";
      plasmashell.show-barcode = [ ];
      plasmashell.show-on-mouse-pos = "Meta+V";
      plasmashell."switch to next activity" = [ ];
      plasmashell."switch to previous activity" = [ ];
      plasmashell."toggle do not disturb" = [ ];
    };
    # Desktop widgets: weather, clock, calendar, now-playing — the set 4.2 adds
    # at install time.
    #
    # There is no plasma-manager option for these (programs.plasma.desktop covers
    # only icons and mouse actions), and writing them into
    # plasma-org.kde.plasma.desktop-appletsrc by hand does not survive either:
    # the panel script DELETES that file before rebuilding the layout. The Plasma
    # scripting API is the supported way in, and priority 4 puts this AFTER the
    # panel script (priority 2) that does the wiping.
    #
    # Coordinates are absolute pixels for a 1920x1200 screen, recovered from
    # this host's ItemGeometries-1920x1200 before the rc file was wiped:
    # weather and calendar along the top, clock and now-playing below them.
    # Adjust for a 4K panel.
    #
    # `config` carries settings that used to live only in the rc file and so
    # died with it — the weather city being the one that actually shows.
    startup.desktopScript."macos_desktop_widgets" = {
      priority = 4;
      text = ''
        ${widgetJs "// Pass 1: make sure all four exist. Positions cascade here."}
      '';
    };

    # Pass 2, and it has to be a SEPARATE script, not a second loop inside the
    # one above. Widget.remove() does not take effect until the running script
    # returns — inside one evaluateScript the containment still sees the old
    # widget, so the re-add cascades again and nothing is corrected. Two scripts
    # means two D-Bus calls, and pass 1 has settled by the time this one runs,
    # which is the whole reason the positions stick.
    #
    # Verified on this host: one script with a doubled loop yields the cascade
    # (calendar y=313, music y=921); two scripts yield the intended layout.
    startup.desktopScript."macos_desktop_widget_positions" = {
      priority = 5;
      text = ''
        ${widgetJs "// Pass 2: re-place each one into the now-settled layout."}
      '';
    };

    configFile = {
      dolphinrc.IconsMode.PreviewSize = 48;
      dolphinrc.MainWindow.MenuBar = "Disabled";   # menubar hidden on the desktop
      dolphinrc."KFileDialog Settings"."Places Icons Auto-resize" = false;
      dolphinrc."KFileDialog Settings"."Places Icons Static Size" = 22;
      katerc.General."Days Meta Infos" = 30;
      katerc.General.PinnedDocuments = "";
      katerc.General."Save Meta Infos" = true;
      katerc.General."Show Full Path in Title" = false;
      katerc.General."Show Menu Bar" = true;
      katerc.General."Show Status Bar" = true;
      katerc.General."Show Tab Bar" = true;
      katerc.General."Show Url Nav Bar" = true;
      katerc."KTextEditor Renderer"."Animate Bracket Matching" = false;
      katerc."KTextEditor Renderer"."Auto Color Theme Selection" = true;
      katerc."KTextEditor Renderer"."Color Theme" = "Breeze Light";
      katerc."KTextEditor Renderer"."Line Height Multiplier" = 1;
      katerc."KTextEditor Renderer"."Show Indentation Lines" = false;
      katerc."KTextEditor Renderer"."Show Whole Bracket Expression" = false;
      katerc."KTextEditor Renderer"."Text Font" = "monospace,9,-1,2,400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
      katerc."KTextEditor Renderer"."Text Font Features" = "";
      katerc."KTextEditor Renderer"."Word Wrap Marker" = false;
      katerc.filetree.editShade = "98,68,134";
      katerc.filetree.listMode = false;
      katerc.filetree.middleClickToClose = false;
      katerc.filetree.shadingEnabled = true;
      katerc.filetree.showCloseButton = false;
      katerc.filetree.showFullPathOnRoots = false;
      katerc.filetree.showToolbar = true;
      katerc.filetree.sortRole = 0;
      katerc.filetree.viewShade = "98,68,134";
      kded5rc.Module-device_automounter.autoload = false;
      kdeglobals.KDE.contrast = 4;
      kdeglobals.KDE.frameContrast = 0.2;
      kdeglobals."KFileDialog Settings"."Allow Expansion" = false;
      kdeglobals."KFileDialog Settings"."Automatically select filename extension" = true;
      kdeglobals."KFileDialog Settings"."Breadcrumb Navigation" = true;
      kdeglobals."KFileDialog Settings"."Decoration position" = 2;
      kdeglobals."KFileDialog Settings"."Show Full Path" = false;
      kdeglobals."KFileDialog Settings"."Show Inline Previews" = true;
      kdeglobals."KFileDialog Settings"."Show Preview" = false;
      kdeglobals."KFileDialog Settings"."Show Speedbar" = true;
      kdeglobals."KFileDialog Settings"."Show hidden files" = false;
      kdeglobals."KFileDialog Settings"."Sort by" = "Name";
      kdeglobals."KFileDialog Settings"."Sort directories first" = true;
      kdeglobals."KFileDialog Settings"."Sort hidden files last" = false;
      kdeglobals."KFileDialog Settings"."Sort reversed" = false;
      kdeglobals."KFileDialog Settings"."Speedbar Width" = 131;
      kdeglobals."KFileDialog Settings"."View Style" = "DetailTree";
      kdeglobals.WM.activeBackground = "24,24,37";
      kdeglobals.WM.activeBlend = "203,166,247";
      kdeglobals.WM.activeForeground = "205,214,244";
      kdeglobals.WM.inactiveBackground = "30,30,46";
      kdeglobals.WM.inactiveBlend = "166,173,200";
      kdeglobals.WM.inactiveForeground = "166,173,200";
      klipperrc.General.MaxClipItems = 500;
      kscreenlockerrc.Daemon.Autolock = false;
      kscreenlockerrc.Daemon.LockOnResume = false;
      kscreenlockerrc.Daemon.Timeout = 0;
      kuriikwsfilterrc.General.EnableWebShortcuts = true;
      kuriikwsfilterrc.General.KeywordDelimiter = ":";
      kuriikwsfilterrc.General.PreferredWebShortcuts = "";
      kuriikwsfilterrc.General.UsePreferredWebShortcutsOnly = false;
      # KWallet off entirely: gnome-keyring is the only Secret Service (see
      # modules/keyring.nix). Leaving it on lets ksecretd claim
      # org.freedesktop.secrets before gnome-keyring on some boots, which
      # reintroduces the split-keychain browser logouts under Plasma.
      kwalletrc.Wallet.Enabled = false;
      kwalletrc.Wallet."First Use" = false;
      plasma-localerc.Formats.LANG = "en_US.UTF-8";

      # --- files rc2nix never reads (it works off a fixed allow-list) ---------
      # Preferences only. The DATA in these same files is deliberately left out:
      # okularrc [Recent Files] and arkrc [ExtractDialog] DirHistory hold client
      # document names and local paths, and this repo is public.
      arkrc.General.LockSidebar = true;
      arkrc.General.ShowSidebar = true;
      arkrc.MainWindow.StatusBar = "Disabled";
      drkonqirc.SystemInformation.CompiledSources = false;
      kate-externaltoolspluginrc.Global.firststart = false;
      katevirc."Kate Vi Input Mode Settings"."Map Leader" = "\\";
      konsolerc.General.ConfigVersion = 1;
      konsolerc.UiSettings.ColorScheme = "";
      okularpartrc."Main View".ShowLeftPanel = false;
      okularrc."Desktop Entry".FullScreen = false;
      okularrc.General.LockSidebar = true;
      okularrc.General.ShowSidebar = true;

      # --- Hyprland keybind parity: app launches -----------------------------
      # Ported from config/hypr/lua/binds.lua. This is the [services][<app>.desktop]
      # _launch form that System Settings > Shortcuts > "Add Application" writes,
      # which is how Meta+Return was bound by hand — it reuses the app's real
      # .desktop instead of synthesising one, so the entry shows the right name
      # and icon in System Settings.
      kglobalshortcutsrc."services/com.mitchellh.ghostty.desktop"._launch = "Meta+Return";
      kglobalshortcutsrc."services/brave-browser.desktop"._launch = "Meta+B";
      kglobalshortcutsrc."services/org.gnome.Nautilus.desktop"._launch = "Meta+E";
      # Hyprland runs gnome-calculator; that is not installed here, so the KDE
      # equivalent takes the binding.
      kglobalshortcutsrc."services/org.kde.kcalc.desktop"._launch = "Meta+Ctrl+C";
      kglobalshortcutsrc."services/rofi-emoji.desktop"._launch = "Meta+Ctrl+E";
    };
  };

  # rofi ships no .desktop for the emoji picker, so provide one and bind it the
  # same [services] way as the real apps above.
  #
  # Deliberately NOT plasma-manager's `hotkeys.commands`: that routes through
  # `xdg.desktopEntries`, and this config sets `xdg.enable = false`, under which
  # home-manager computes desktopEntries but never writes them — the shortcut
  # would register against a .desktop that does not exist and launch nothing.
  home.file.".local/share/applications/rofi-emoji.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Emoji Picker
    Exec=rofi -modi emoji -show emoji
    NoDisplay=true
    StartupNotify=false
  '';

  # The macOS look's assets. home-manager puts ~/.nix-profile/share on
  # XDG_DATA_DIRS, which is how Plasma finds the styles, plasmoids, icons and
  # cursors below — no kpackagetool6 install step is involved.
  home.packages = [
    sumac-theme
    liquidglass-widgets

    # NOT optional: Sumac-Night/index.theme is `Inherits=WhiteSur-dark` and
    # carries no icons of its own. Drop this and every icon falls back to hicolor.
    pkgs.whitesur-icon-theme

    pkgs.whitesur-cursors        # workspace.cursor.theme
    pkgs.application-title-bar   # the top panel's window-title widget
  ];
}
