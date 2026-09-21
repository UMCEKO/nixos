{ config, lib, pkgs, ... }:

let
  cfg = config.services.vice;
in
{
  options.services.vice = {
    enable = lib.mkEnableOption "the Vice game clip recorder";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../pkgs/vice-clipper.nix { };
      description = "The Vice package to use.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the clipping daemon for the whole graphical session.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # TAG+="uaccess" on the event nodes, so the hotkey listener reads the
    # keyboard without the user being in the `input` group.
    services.udev.packages = [ cfg.package ];

    systemd.user.services.vice = {
      description = "Vice game clip recorder daemon";
      after = [ "graphical-session.target" ];
      wantedBy = lib.optionals cfg.autoStart [ "graphical-session.target" "default.target" ];

      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/vice start --no-open-ui";
        Restart = "on-failure";
        RestartSec = 3;
        PassEnvironment = "WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS XDG_SESSION_TYPE XDG_CURRENT_DESKTOP";
      };
    };
  };
}
