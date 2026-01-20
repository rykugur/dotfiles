{
  config,
  lib,
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    ./3dp.nix
    ./desktop.nix
    ./dev.nix
    ./gaming.nix
    ./server.nix
    ./terminal.nix
  ];

  config = {
    time.timeZone = "America/Chicago";

    # Select internationalisation properties.
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

    # Necessary for using flakes on this system.
    environment = {
      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      etc = lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry;
    };

    nix = {
      # using nh now instead
      # gc = {
      #   automatic = true;
      #   options = "--delete-older-than 10d";
      # };

      optimise.automatic = true;

      nixPath = [ "/etc/nix/path" ];

      registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
        (lib.filterAttrs (_: lib.isType "flake")) inputs
      );

      settings = {
        experimental-features = "nix-command flakes pipe-operators";

        # Deduplicate and optimize nix store
        auto-optimise-store = true;
      };
    };

    nixpkgs = {
      overlays = [
        # If you want to use overlays exported from other flakes:
        # neovim-nightly-overlay.overlays.default
        outputs.overlays.additions
        outputs.overlays.modifications

        # Or define it inline, for example:
        # (final: prev: {
        #   hi = final.hello.overrideAttrs (oldAttrs: {
        #     patches = [ ./change-hello-to-hi.patch ];
        #   });
        # })
      ];
      config.allowUnfree = true;
    };
  };
}
