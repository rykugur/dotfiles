{
  description = "Swoleflake";

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

      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in
    {
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      devShells."x86_64-linux" =
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ nodejs_21 ];
          };
        };

      nixosConfigurations = {
        # primary/gaming desktop
        "jezrien" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/jezrien/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        # laptop
        "taln" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/taln/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        # # homelab
        # tanavast = nixpkgs.lib.nixosSystem {
        #   modules = [ ./hosts/tanavast/configuration.nix];
        #   specialArgs = { inherit inputs outputs; };
        # };
      };

      homeConfigurations = {
        "dusty@jezrien" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home/dusty/jezrien.nix
          ];
        };
        "dusty@taln" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home/dusty/taln.nix
          ];
        };
      };
    };
}

