# Gaming stack — replaces CachyOS's cachyos-gaming-meta.
# Uses NixOS program modules (declarative) instead of loose packages.
{ pkgs, ... }:
{
  programs.steam = {
    enable = true;                       # unfree — allowed via nixpkgs.config.allowUnfree
    gamescopeSession.enable = true;      # "Steam (gamescope)" session in SDDM
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];  # ProtonGE, like protonup gave you
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
