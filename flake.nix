{
  description = "umceko's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager as a proper flake input, replacing the fetchTarball.
    # `follows` makes it use the SAME nixpkgs as above (no second copy).
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Laptop hardware quirks. There is NO profile for the EliteBook 6 G1a (HP
    # dropped the 3-digit naming this generation), so hosts/laptop imports the
    # generic common/* modules directly — which is all the closest existing
    # profile, hp/elitebook/845/g8, does anyway.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";  # else it drags in a second nixpkgs
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Secure Boot: signed bootloader/kernel with your own keys (sbctl).
    # master, not v0.4.2 — the tagged release still sets boot.bootspec.enable,
    # which nixos-unstable now hard-asserts against.
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used ONLY for the proton-cachyos package (prebuilt via nyx-cache).
    # Do NOT import its module/overlay — it world-rebuilds core packages
    # (that's what broke gnugrep when we tried the CachyOS kernel).
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Your SteelSeries ChatMix daemon.
    chatmixd.url = "github:UMCEKO/chatmixd";

    # HUSH — Maxine denoiser virtual mic. `follows` reuses this nixpkgs (no 2nd copy).
    # The GUI + hushd service come from its home-manager module (imported in
    # hosts/desktop/home.nix — it needs CUDA, so desktop only).
    hush = {
      url = "github:UMCEKO/hush";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # Modules every host gets. Per-host module lists live in hosts/<name>.
      baseModules = [
        ./modules/common.nix
        home-manager.nixosModules.home-manager
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      mkHost = { modules }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = baseModules ++ modules;
      };
    in
    {
      # Attribute name must match networking.hostName — the `nrs` alias in
      # modules/common.nix builds ~/nixos#${config.networking.hostName}.
      nixosConfigurations = {
        nixos = mkHost {
          modules = [
            ./hosts/desktop
            inputs.chatmixd.nixosModules.default
          ];
        };

        laptop = mkHost {
          modules = [ ./hosts/laptop ];
        };
      };
    };
}
