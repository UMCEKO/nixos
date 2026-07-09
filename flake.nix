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

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # `nixos` here must match the `#nixos` you build with below.
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        inputs.lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}
