{ inputs, outputs, lib, config, pkgs, hostname, username, roles, ... }: {
  imports = [
    ../default.nix

    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.nixosModules
    roles
  ] ++ (with inputs.nixos-hardware.nixosModules; [ common-pc common-pc-ssd ]);

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = hostname;
    search = [ "router.lan" ];
    nameservers = [ "10.3.8.157" ];

    networkmanager = { enable = true; };
  };

  nixpkgs = {
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
    config.allowUnfree = true;
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    optimise.automatic = true;

    nixPath = [ "/etc/nix/path" ];

    registry = (lib.mapAttrs (_: flake: { inherit flake; }))
      ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      substituters = [ "https://cache.saumon.network/proxmox-nixos" ];
      trusted-public-keys =
        [ "proxmox-nixos:nveXDuVVhFDRFx8Dn19f1WDEaNRJjPrF2CPD2D+m1ys=" ];
    };
  };

  environment = {
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    variables = {
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };

  users.users = {
    ${username} = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/${username}";
      extraGroups = [ "wheel" "networkmanager" "corectrl" ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  programs._1password = { enable = true; };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
