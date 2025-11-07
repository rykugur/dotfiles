{
  description = "Swoleflake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ### de/wm  stuff
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-qtutils.url = "github:hyprwm/hyprland-qtutils";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell.url = "github:AvengeMedia/DankMaterialShell";
    noctalia.url = "github:noctalia-dev/noctalia-shell";

    ### gaming ish
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.url = "github:LovingMelody/nix-citizen";

    ### helix
    helix.url = "github:helix-editor/helix";

    ### random stuff
    atuin.url = "github:atuinsh/atuin";
    luarocks-nix.url = "github:nix-community/luarocks-nix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zjstatus.url = "github:dj95/zjstatus";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      inherit (self) outputs;

      lib = nixpkgs.lib // home-manager.lib;

      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
    in {
      devShells =
        forEachSystem (pkgs: import ./shells { inherit inputs pkgs; });

      overlays = import ./overlays { inherit inputs; };

      baseModules = import ./modules/base;
      darwinModules = import ./modules/darwin;
      nixosModules = import ./modules/nixos;
      hmModules = import ./modules/home-manager;

      modules = import ./modules;

      nixosConfigurations = let username = "dusty";
      in {
        # primary/gaming desktop
        "jezrien" = nixpkgs.lib.nixosSystem {
          modules = [
            outputs.baseModules
            outputs.nixosModules
            outputs.modules

            ./roles

            ./hosts/jezrien
          ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "jezrien";
            inherit username;
          };
        };
      };

      darwinConfigurations = {
        # home macbook pro
        "taln" = nix-darwin.lib.darwinSystem {
          modules = [
            outputs.baseModules
            outputs.darwinModules

            ./hosts/taln/configuration.nix
          ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "taln";
            username = "dusty";
          };
        };

        # work macbook
        "HJ0704F9VK" = nix-darwin.lib.darwinSystem {
          modules = [ ./hosts/work-macbook/configuration.nix ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "";
            username = "dustin.jerome";
          };
        };
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nix-citizen.cachix.org"
      "https://helix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };
}
