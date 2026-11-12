# crew (crew-sh/crew): the usher daemon as a user service, and `cargo` routed through `crew cargo` (mbx + usher build grants).
{ pkgs, ... }:

let
  crew = pkgs.callPackage ../pkgs/crew.nix { };
  # Drops itself and mbx's shim from PATH so crew-depot, mbx and the real cargo below never loop back here.
  cargoShim = pkgs.writeShellScriptBin "cargo" ''
    self=$(dirname "$(readlink -f "$0")")
    PATH=$(printf '%s' "$PATH" | tr ':' '\n' | grep -vx -e "$self" -e "$HOME/.local/share/crew/bin" -e "$HOME/.local/share/mbx/bin" | paste -sd:)
    export PATH
    [ "$#" -eq 0 ] || [ "''${CREW_CARGO:-1}" = 0 ] && exec cargo "$@"
    exec ${crew}/bin/crew cargo "$@"
  '';
in
{
  home.packages = [ crew ];

  home.file.".local/share/crew/bin/cargo".source = "${cargoShim}/bin/cargo";

  systemd.user.services.crew-usher = {
    Unit = {
      Description = "crew usher: admission for heavy jobs on this machine";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${crew}/bin/crew-usher";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
