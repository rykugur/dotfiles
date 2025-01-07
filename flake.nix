{
  description = "Swoleflake";

  inputs = {
    stable-nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
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
    mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    # gBar.url = "github:scorpion-26/gBar";

    ### gaming ish
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    umu = {
      # url =
      #   "git+https://github.com/Open-Wine-Components/umu-launcher/?dir=packaging/nix&submodules=1";
      url =
        "github:Open-Wine-Components/umu-launcher/59a82ea8cd284c7535bc06b8f6156abb7da96f6a?dir=packaging/nix";
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs.follows = "stable-nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";

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

      systems = [ "x86_64-linux" "aarch64-linux" ];
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
        # razer blade stealth laptop
        "taln" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/taln ];
          specialArgs = {
            inherit inputs outputs;
            hostname = "taln";
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
        # };
        # # homelab
        # tanavast = nixpkgs.lib.nixosSystem {
        #   modules = [ ./hosts/tanavast/configuration.nix];
        #   specialArgs = { inherit inputs outputs; };
        # };
      };

      darwinConfigurations = {
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
