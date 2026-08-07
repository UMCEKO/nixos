# Gaming stack — replaces CachyOS's cachyos-gaming-meta.
# Uses NixOS program modules (declarative) instead of loose packages.
{ pkgs, inputs, ... }:
let
  # Steam hides the sniper/soldier containers from the per-game "Compatibility"
  # dropdown (their toolmanifest has no display_name), so native Linux games can
  # only ever be forced onto scout — which is too old for e.g. Dead Cells (no
  # libdecor-0 / libXss). This tiny compat tool just gives Steam's *own* sniper
  # install a display_name so it becomes selectable. It ships only a
  # compatibilitytool.vdf; the toolmanifest is read from install_path (Steam's
  # sniper dir). from/to oslist = linux → shows for native Linux games, the same
  # slot scout occupies. Set it per-game via Properties → Compatibility.
  sniper-selectable = pkgs.writeTextDir "compatibilitytool.vdf" ''
    "compatibilitytools"
    {
      "compat_tools"
      {
        "SLR-sniper-manual"
        {
          "install_path" "/home/umceko/.local/share/Steam/steamapps/common/SteamLinuxRuntime_sniper"
          "display_name" "Steam Linux Runtime 3.0 (sniper) [manual]"
          "from_oslist"  "linux"
          "to_oslist"    "linux"
        }
      }
    }
  '';
in
{
  programs.steam = {
    enable = true;                       # unfree — allowed via nixpkgs.config.allowUnfree
    gamescopeSession.enable = true;      # "Steam (gamescope)" session in SDDM
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin                 # ProtonGE, like protonup gave you
      # From the chaotic flake, package only (see flake.nix warning).
      inputs.chaotic.legacyPackages.${pkgs.system}.proton-cachyos_x86_64_v3
      sniper-selectable                  # makes Steam's sniper container selectable for native games
    ];
  };

  # Prebuilt chaotic packages (proton-cachyos) — avoids compiling Proton.
  nix.settings = {
    extra-substituters = [ "https://nyx-cache.chaotic.cx/" ];
    extra-trusted-public-keys = [ "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=" ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;                   # lets gamescope raise its scheduling priority
  };
  programs.gamemode = {
    enable = true;                       # `gamemoderun %command%` in Steam launch opts
    settings.general = {
      renice = 10;
      inhibit_screensaver = 1;
    };
  };

  # 32-bit graphics libs — needed by Steam/Proton/Wine (replaces all the lib32-* pkgs).
  hardware.graphics.enable32Bit = true;

  environment.systemPackages = with pkgs; [
    mangohud          # replaces mangojuice/mangohud
    protonup-qt       # GUI Proton manager (was protonplus/protonup-qt)
    protontricks
    prismlauncher     # Minecraft launcher
    r2modman          # mod manager
    wineWow64Packages.stable
    winetricks
    lutris heroic     # extra launchers you had (heroic was in your configs)
  ];
}
