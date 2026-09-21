# Session logs and Claude instructions, synced desktop <-> laptop.
{ config, lib, ... }:

let
  # From `syncthing generate`; the service reuses key.pem, so these stay stable.
  devices = {
    nixos.id = "BNVEMQD-4LOXP2J-E2QNIV6-I7RPKXA-YKJVW5N-7NREBZU-5GYR644-R7W3YQ6";
    elitebook.id = "44QY3PG-JHY3EGY-DRQR2HF-DSE3QWI-724QB4H-AG2CNLM-AWEVBIG-NNV6WQA";
  };

  # Syncthing rejects being told about itself.
  others = builtins.removeAttrs devices [ config.networking.hostName ];
  peers = builtins.attrNames others;
in
{
  services.syncthing = {
    # ~ is 0700, so the syncthing system user cannot traverse it; run as umceko.
    enable = lib.mkDefault true;
    user = lib.mkDefault "umceko";
    group = lib.mkDefault "users";
    dataDir = lib.mkDefault "/home/umceko";
    openDefaultPorts = lib.mkDefault true;

    # True deletes whatever is not declared here; the desktop has GUI-managed folders.
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      devices = others;

      folders."claude-transcripts" = {
        path = "/home/umceko/.claude/projects";
        devices = peers;
        # Low, so handing a session to the other machine leaves no unsynced tail.
        fsWatcherDelayS = 5;
      };

      # Kept out of .claude/projects because Syncthing forbids nested folder roots.
      folders."claude-config" = {
        path = "/home/umceko/.claude-shared";
        devices = peers;
        # Instructions, not logs: small enough that old copies are worth keeping.
        versioning = {
          type = "simple";
          params.keep = "5";
        };
      };
    };
  };
}
