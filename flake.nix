{
  description = "Swoleflake";

  # TODO: fish plugins?
  # TODO: btrfs test with multiple devices
  # TODO: figure out any gotchas with nvidia

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , rust-overlay
    , ...
    } @ inputs:
    let
      inherit (self) outputs;

      username = "dusty";
      hostname = "jezrien";

      overlays = { rust-overlay = rust-overlay; };

      wm = "hyprland";

      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname overlays wm; };
          modules = [
            ./nixos/${hostname}/configuration.nix
          ];
        };
      };

      homeConfigurations = {
        "${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system}; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs username hostname wm; };
          modules = [
            ./home-manager/${username}/home.nix
          ];
        };
      };
    };
}

