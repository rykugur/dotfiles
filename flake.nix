{
  description = "Swoleflake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";

    ### hyprland stuff
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";
    swayfx.url = "github:WillPower3309/swayfx";
    gBar.url = "github:scorpion-26/gBar";
    ags.url = "github:Aylur/ags";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    umu = {
      url =
        "git+https://github.com/Open-Wine-Components/umu-launcher/?dir=packaging/nix&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    luarocks-nix.url = "github:nix-community/luarocks-nix";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;

      lib = nixpkgs.lib // home-manager.lib;

      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
      roles = import ./roles;
    in {
      devShells =
        forEachSystem (pkgs: import ./shells { inherit inputs pkgs; });

      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules;

      nixosConfigurations = let username = "dusty";
      in {
        # primary/gaming desktop
        "jezrien" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/jezrien ];
          specialArgs = {
            inherit inputs outputs roles;
            hostname = "jezrien";
            inherit username;
          };
        };
        # razer blade stealth laptop
        "taln" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/taln ];
          specialArgs = {
            inherit inputs outputs roles;
            hostname = "taln";
            inherit username;
          };
        };
        # raspberry pi 5
        "taldain" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/taldain ];
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs outputs roles;
            hostname = "taldain";
            inherit username;
          };
        };
        # # homelab
        # tanavast = nixpkgs.lib.nixosSystem {
        #   modules = [ ./hosts/tanavast/configuration.nix];
        #   specialArgs = { inherit inputs outputs; };
        # };
      };
    };
}
