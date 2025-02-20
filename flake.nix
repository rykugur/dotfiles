{
  description = "Swoleflake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";

    # proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-stable";

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
    hyprland-qtutils.url = "github:hyprwm/hyprland-qtutils";
    # mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    # gBar.url = "github:scorpion-26/gBar";

    ### gaming ish
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.url = "github:LovingMelody/nix-citizen";

    ### random stuff
    luarocks-nix.url = "github:nix-community/luarocks-nix";
    # zen-browser.url = "github:MarceColl/zen-browser-flake";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    # zellij status bar
    zjstatus.url = "github:dj95/zjstatus";

    ghostty.url = "github:ghostty-org/ghostty";
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

      nixosConfigurations = let username = "dusty";
      in {
        # primary/gaming desktop
        "jezrien" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/jezrien ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "jezrien";
            inherit username;
          };
        };
        # # raspberry pi 5 - dns ad blocker, klipper server
        # "taldain" = nixpkgs.lib.nixosSystem {
        #   modules = [ ./hosts/taldain ];
        #   system = "aarch64-linux";
        #   specialArgs = {
        #     inherit inputs outputs;
        #     hostname = "taldain";
        #     username = "shazbot";
        #   };
      };

      darwinConfigurations = {
        # home macbook pro
        "rayse" = nix-darwin.lib.darwinSystem {
          modules = [ ./hosts/rayse/configuration.nix ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "rayse";
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
}
