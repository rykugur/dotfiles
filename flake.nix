{
  description = "Swoleflake";

  # TODO: fish plugins?

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    # rust-overlay.url = "github:oxalica/rust-overlay";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , ...
    } @ inputs:
    let
      inherit (self) outputs;

      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {
        # primary/gaming desktop
        jezrien = nixpkgs.lib.nixosSystem {
          modules = [ ./nixos/jezrien/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        # # homelab
        # tanavast = nixpkgs.lib.nixosSystem {
        #   modules = [ ./nixos/tanavast/configuration.nix];
        #   specialArgs = { inherit inputs outputs; };
        # };
      };

      homeConfigurations = {
        "dusty@jezrien" = home-manager.lib.homeManagerConfiguration {
          # modules = [ ./home-manager/dusty/home.nix ];
          # pkgs = nixpkgs.legacyPackages."x86_64-linux";
          # extraSpecialArgs = {
          #   inherit inputs outputs;
          # };
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/dusty/home.nix
          ];
        };
      };

      # devShells.${system} = {
      #   default = pkgs.mkShell {
      #     nativeBuildInputs = [
      #       pkgs.nodejs_21
      #     ];
      #   };
      # };
    };
}

