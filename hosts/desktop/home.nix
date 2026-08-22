# home-manager bits that need THIS box's hardware: the 4090 (HUSH/Maxine needs
# CUDA), the Steam library (proton-cachyos), VR (opencomposite), and the OLED
# panel on DP-3 (hyproled).
{ config, pkgs, lib, inputs, ... }:
let
  # hyproled — OLED burn-in shader (github.com/mklan/hyproled). Packaged from
  # source since it's not in nixpkgs. Wrapped with hyprctl on PATH.
  hyproled = pkgs.stdenv.mkDerivation {
    pname = "hyproled";
    version = "unstable-2026-07-05";
    src = pkgs.fetchFromGitHub {
      owner = "mklan";
      repo = "hyproled";
      rev = "5fd505a3108e3d52085915f28fe7c10ba9392f01";
      sha256 = "0crqjkybyygvqlrjhr9yrd0r1lslkglwlpq41v5gjhf8c9im5il7";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontBuild = true;
    installPhase = ''
      install -Dm755 hyproled $out/bin/hyproled
      wrapProgram $out/bin/hyproled \
        --prefix PATH : ${lib.makeBinPath [ pkgs.hyprland pkgs.gnugrep pkgs.gawk pkgs.coreutils ]}
    '';
  };
in
{
  # HUSH: installs the `hush` GUI + runs the `hushd` denoiser as a user service
  # (the module bakes the runtime SDK dir into the unit's LD_LIBRARY_PATH; the SDK
  # itself is downloaded once by the app on first launch).
  imports = [ inputs.hush.homeManagerModules.default ];
  services.hush.enable = true;

  # Stable path to proton-cachyos for umu-launcher (PROTONPATH) — survives
  # updates, unlike a raw /nix/store path. /bin is the compat-tool root.
  home.file.".local/share/proton-cachyos".source =
    "${inputs.chaotic.legacyPackages.${pkgs.system}.proton-cachyos_x86_64_v3}/bin";

  # Register proton-cachyos as a Steam compatibility tool. It must be a REAL,
  # writable directory, NOT a store symlink: Steam/Proton/BSManager write a lock
  # file into the Proton folder on launch, which fails on the read-only /nix/store
  # (BSManager rejects it as an "invalid proton folder"). So copy it out with write
  # perms each activation. Restart Steam after a rebuild to pick it up.
  home.activation.protonCachyosCompatTool =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src="${inputs.chaotic.legacyPackages.${pkgs.system}.proton-cachyos_x86_64_v3}/bin"
      dst="$HOME/.local/share/Steam/compatibilitytools.d/proton-cachyos"
      rm -rf "$dst"
      mkdir -p "$dst"
      cp -rT --no-preserve=ownership "$src" "$dst"   # keep modes (+x on proton/wine), just not root ownership
      chmod -R u+w "$dst"                            # add write on top of the store's read-only modes
      # BSManager validates a Proton folder by requiring files/bin/wine64, but
      # proton-cachyos uses new WoW64 wine (single `wine`, no wine64). Symlink it
      # so BSManager accepts the folder (Proton runs via its `proton` script).
      ln -sf wine "$dst/files/bin/wine64"
    '';

  # OpenComposite (OpenVR->OpenXR shim) for VR_OVERRIDE consumers. Nix-built —
  # an Arch-built copy can't load here (glibc/GL deps), and nix store paths
  # stay visible inside the Steam Linux Runtime container.
  home.file.".local/share/opencomposite".source =
    "${pkgs.opencomposite}/lib/opencomposite";

  # OLED burn-in: shift pixels in the bar area hourly (your old hyproled units).
  # DISABLED 2026-07-08 (per request). Re-enable by uncommenting all three below;
  # the `hyproled` derivation up top stays defined and ready.
  # home.packages = [ hyproled ];
  # systemd.user.services.hyproled = {
  #   Unit.Description = "Shift OLED pixels on bar area";
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${hyproled}/bin/hyproled -s -m 0 -a 0:0:3840:75";
  #   };
  # };
  # systemd.user.timers.hyproled = {
  #   Unit.Description = "Hourly OLED pixel shift for bar area";
  #   Timer = { OnBootSec = "5min"; OnUnitActiveSec = "1h"; Persistent = true; };
  #   Install.WantedBy = [ "timers.target" ];
  # };
}
