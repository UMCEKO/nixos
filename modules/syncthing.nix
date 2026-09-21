# Claude session transcripts, synced desktop <-> laptop, so a session started on
# one machine can be resumed on the other without copying a .jsonl by hand.
#
# Only ~/.claude/projects is shared. The rest of ~/.claude is machine-bound:
# shell-snapshots/ embeds /nix/store paths that do not exist in the other host's
# generation (sourcing one there breaks every shell Claude opens), and
# .credentials.json is an OAuth token each machine should hold its own copy of.
#
# Transcripts are append-only JSONL and Syncthing has no merge, so run one
# machine at a time. Both appending to the same session produces a
# .sync-conflict- twin rather than a merge — that file is the safety net, which
# is why no versioning is set here: these transcripts run to tens of MB each
# (2.8G on the desktop, 350M here), and versioning keeps a full copy per
# replacement, so a live session would fill the disk with near-identical
# snapshots of itself.
#
# hosts/desktop/default.nix already declares the service. Everything that
# overlaps with it is mkDefault, so that block keeps winning there and this only
# has to carry the two devices and the folder; the laptop, which declares
# nothing of its own, gets the service from the defaults below.
{ config, lib, ... }:

let
  # `syncthing generate --home ~/.config/syncthing` on each; the service reuses
  # the existing key.pem, so these stay stable across rebuilds.
  devices = {
    nixos.id = "BNVEMQD-4LOXP2J-E2QNIV6-I7RPKXA-YKJVW5N-7NREBZU-5GYR644-R7W3YQ6";
    elitebook.id = "44QY3PG-JHY3EGY-DRQR2HF-DSE3QWI-724QB4H-AG2CNLM-AWEVBIG-NNV6WQA";
  };

  # Syncthing is told about the other machine, never about itself.
  others = builtins.removeAttrs devices [ config.networking.hostName ];
in
{
  services.syncthing = {
    # ~ is 0700, so the syncthing system user cannot traverse it; run as umceko.
    enable = lib.mkDefault true;
    user = lib.mkDefault "umceko";
    group = lib.mkDefault "users";
    dataDir = lib.mkDefault "/home/umceko";
    openDefaultPorts = lib.mkDefault true;

    # The desktop shares MayaMiya and youtube with the "Ask" device, set up
    # through the GUI. Declarative authority is the default and would delete
    # both on the first switch, so this only ever adds.
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      devices = others;

      folders."claude-transcripts" = {
        path = "/home/umceko/.claude/projects";
        devices = builtins.attrNames others;
        # A live session appends every few seconds. Batching the watcher keeps
        # it from rehashing a 58MB transcript on each write; nothing waits on
        # it, since a handoff is deliberate.
        fsWatcherDelayS = 60;
      };
    };
  };
}
