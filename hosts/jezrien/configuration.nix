{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix

    outputs.nixosModules.base

    outputs.nixosModules.btrfs

    outputs.nixosModules.pipewire
    inputs.nix-gaming.nixosModules.pipewireLowLatency

    outputs.nixosModules.gnome
    outputs.nixosModules.hyprland
    outputs.nixosModules.keebs
    outputs.nixosModules.libvirtd
    outputs.nixosModules.ssh

    outputs.nixosModules._1password
    outputs.nixosModules.gaming
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd-pstate
    common-gpu-amd
  ]);

  hardware = {
    cpu.amd.updateMicrocode = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_9;
    kernel = {
      sysctl = {
        # for Star Citizen
        "vm.max_map_count" = 16777216;
        "fs.file-max" = 524288;
      };
    };
    loader.systemd-boot.enable = true;
  };

  security = {
    pam = {
      u2f = {
        enable = true;
      };
    };
  };

  networking = {
    hostName = "jezrien";
    search = [ "pihole.lan" "pihole" "8.8.8.8" "8.8.4.4" ];
    extraHosts = ''
      127.0.0.1 modules-cdn.eac-prod.on.epicgames.com
    '';
  };

  services = {
    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    # displayManager.sddm.enable = true;
    # desktopManager.plasma6.enable = true;

    xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };
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
    ];
    config.allowUnfree = true;
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  environment.etc =
    lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    optimise.automatic = true;

    nixPath = [ "/etc/nix/path" ];

    registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://nix-citizen.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      ];
    };
  };

  programs = {
    corectrl.enable = true;

    dconf.enable = true;

    fish = {
      enable = true;
      vendor.functions.enable = true;
    };

    nix-ld.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    home-manager
    neovim
  ];

  environment.variables = {
    VDPAU_DRIVER = "radeonsi";
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  users.users = {
    dusty = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/dusty";
      extraGroups = [ "wheel" "networkmanager" "corectrl" ];
      shell = pkgs.fish;
    };
  };

  time.timeZone = "America/Chicago";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
