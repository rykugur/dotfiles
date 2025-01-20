{ inputs, outputs, lib, config, pkgs, hostname, username, ... }: {
  imports = [
    ../default.nix

    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.nixosModules
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-laptop-ssd
    common-cpu-intel
    common-gpu-nvidia # this points at the common/gpu/nvidia/prime.nix file
  ]);

  hardware = {
    nvidia = {
      modesetting.enable = true; # required

      powerManagement = {
        enable = true;
        finegrained = false;
      };

      open = false; # don't use open source kernel module
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;

      prime = {
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:59:00:0";
      };
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  security = {
    pam = {
      services.${username}.enableGnomeKeyring = true;
      u2f = {
        enable = true;
        settings = { cue = true; };
      };
    };
    polkit.enable = true;
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  networking = {
    hostName = hostname;
    search = [ "taldain" "8.8.8.8" "8.8.4.4" ];
    networkmanager.enable = true;
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

  environment = {
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    systemPackages = with pkgs; [ polkit_gnome ];
  };

  users.users = {
    dusty = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/dusty";
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  programs = {
    nix-ld.enable = true;
    seahorse.enable = true;
  };

  services = {
    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    upower.enable = true;

    xserver = {
      enable = true;
      displayManager.startx.enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    blueman = { enable = true; };
    logind = { lidSwitch = "suspend"; };
  };

  ### custom module stuff

  rhx = {
    _1password.enable = true;
    btrfs.enable = true;
    fonts.enable = true;
    gamemode.enable = true;
    pipewire.enable = true;
    razer.enable = true;
    ssh.enable = true;
    steam.enable = true;

    # DE stuff
    hyprland.enable = true;
    kde.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ../../users/${username}/home.nix; };
    backupFileExtension = "bak";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
