{ ... }:
{
  flake.modules.nixos.nix-defaults =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    {
      time.timeZone = "America/Chicago";

      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_GB.UTF-8"; # for 24 hour format
      };

      environment.systemPackages = with pkgs; [
        git
        neovim
        nix-search-cli
      ];

      environment.etc = lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry;

      nix = {
        optimise.automatic = true;
        nixPath = [ "/etc/nix/path" ];
        registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
          (lib.filterAttrs (_: lib.isType "flake")) inputs
        );
        settings = {
          experimental-features = "nix-command flakes pipe-operators";
          auto-optimise-store = true;
        };
      };

      nixpkgs = {
        overlays = [
          inputs.self.overlays.additions
          inputs.self.overlays.modifications
        ];
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
          permittedInsecurePackages = [
            "electron-25.9.0"
            "nexusmods-app-unfree-0.21.1"
          ];
        };
      };
    };
}
