# Claude Code MCP servers, the same on both hosts; their scripts live in the Syncthing folder.
{ config, pkgs, lib, ... }:
let
  home = config.home.homeDirectory;
  shared = "${home}/.claude-shared/mcp";
  hypr-computer-mcp = pkgs.callPackage ../pkgs/hypr-computer-mcp.nix { };

  # Merged into ~/.claude.json, which also holds per-machine login and state, so the file itself is never synced.
  servers = {
    hypr-computer = {
      type = "stdio";
      command = lib.getExe hypr-computer-mcp;
      args = [ ];
      env = { };
    };
    vortex = {
      type = "stdio";
      command = lib.getExe pkgs.nodejs;
      args = [ "${home}/.claude/mcp/vortex-tools.mjs" ];
      env = { };
    };
  };
  serversJson = pkgs.writeText "claude-mcp-servers.json" (builtins.toJSON servers);
  jq = lib.getExe pkgs.jq;
in
{
  home.packages = [ hypr-computer-mcp ];

  home.file.".claude/mcp".source = config.lib.file.mkOutOfStoreSymlink shared;

  # A host that already has a real ~/.claude/mcp hands its scripts to the shared folder before the link replaces it.
  home.activation.claudeMcpAdopt = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -d "${home}/.claude/mcp" ] && [ ! -L "${home}/.claude/mcp" ]; then
      run mkdir -p "${shared}"
      run cp -an "${home}/.claude/mcp/." "${shared}/"
      run mv "${home}/.claude/mcp" "${home}/.claude/mcp.adopted-$(date +%s)"
    fi
  '';

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    file="${home}/.claude.json"
    [ -f "$file" ] || echo '{}' > "$file"
    tmp="$(mktemp "$file.XXXXXX")"
    if ${jq} --slurpfile s ${serversJson} '.mcpServers = ((.mcpServers // {}) + $s[0])' "$file" > "$tmp"; then
      run mv "$tmp" "$file"
    else
      rm -f "$tmp"
      echo "claude.nix: could not merge MCP servers into $file" >&2
    fi
  '';
}
