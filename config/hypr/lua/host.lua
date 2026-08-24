-- Host identity for the shared Hyprland config.
--
-- config/hypr is live-symlinked into every host (home/common.nix), so anything
-- that differs between machines has to branch at runtime rather than be
-- hardcoded. Reading /etc/hostname is the cheapest source of truth that works
-- inside a symlinked config dir — home-manager cannot write a generated file
-- into it (the whole dir is one mkOutOfStoreSymlink).
--
-- Names must match flake.nix's nixosConfigurations.

local M = {}

-- Single-panel hosts. `is_laptop` is about the DISPLAY LAYOUT, not the form
-- factor: it selects the one-screen monitor/workspace/window-pinning branches.
-- Adding the second laptop is one line here — that is the whole reason the
-- host is called "elitebook" and not "laptop".
local SINGLE_PANEL = {
  elitebook = true,
}

local function read_hostname()
  local f = io.open("/etc/hostname", "r")
  if not f then return "" end
  local h = f:read("l") or ""
  f:close()
  return (h:gsub("%s+", ""))
end

M.name = read_hostname()
M.is_laptop  = SINGLE_PANEL[M.name] == true
M.is_desktop = (M.name == "nixos")

return M
