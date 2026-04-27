{
  description = "Swoleflake";

  inputs = {
    ### nix/flake stuff
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    import-tree.url = "github:vic/import-tree";
    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ###

    ### de/wm stuff
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-qtutils = {
      url = "github:hyprwm/hyprland-qtutils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # bars/shells
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ###

    ### gaming ish
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    ###

    ### random stuff
    helix.url = "github:helix-editor/helix";
    ryze312-stackpkgs = {
      url = "github:ryze312/stackpkgs"; # for audiorelay
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ###

    ### ai stuff
    hermes-agent.url = "github:NousResearch/hermes-agent";
    karpathy-skills = {
      url = "github:forrestchang/andrej-karpathy-skills";
      flake = false;
    };
    hermes-webui = {
      url = "github:nesquena/hermes-webui";
      flake = false;
    };

    #  plugins
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };
    context7 = {
      url = "github:upstash/context7";
      flake = false;
    };
    # agent skills
    skills-anthropic = {
      url = "github:anthropics/skills";
      flake = false;
    };
    skills-vercel = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };
    ###
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      self,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { inputs, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          allPackages = import ./pkgs { inherit pkgs; };
        in
        {
          # Filter out packages whose meta.platforms doesn't include the current
          # system. Without this, `nix flake check` fails because it evaluates
          # every package under each system and asserts platform compatibility.
          packages = pkgs.lib.filterAttrs (
            _: pkg: builtins.elem system (pkg.meta.platforms or [ system ])
          ) allPackages;
          devShells = import ./shells { inherit inputs pkgs; };
        };

      flake = {
        modules = { };

        overlays = import ./overlays { inherit inputs; };

        nixosConfigurations = { };

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
