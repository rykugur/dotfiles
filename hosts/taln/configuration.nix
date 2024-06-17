{ inputs, outputs, lib, config, pkgs, hostname, username, roles, ... }: {
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    inputs.nix-gaming.nixosModules.pipewireLowLatency
    outputs.nixosModules
    roles
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-laptop-ssd
    common-cpu-intel
    common-gpu-nvidia
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
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:59:00:0";
      };
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    openrazer = {
      enable = true;
      users = [ "${username}" ];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_9;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  security = {
    pam = { u2f = { enable = true; }; };
    polkit.enable = true;
  };

  networking = {
    hostName = hostname;
    search = [ "pihole.lan" "pihole" "8.8.8.8" "8.8.4.4" ];
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
      outputs.overlays.additions
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

    systemPackages = with pkgs;
      [ git neovim nix-search-cli ]
      ++ [ (import ../../scripts/hyprland-suspend.nix { inherit pkgs; }) ];
  };

  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  users.users = {
    dusty = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/dusty";
      extraGroups = [ "wheel" "networkmanager" "openrazer" ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  roles.gaming.enable = true;

  modules = {
    gaming = {
      starcitizen.enable = true;
      starsector.enable = true;
    };

    programs = {
      _1password.enable = true;
      firefox.enable = true;
      fish.enable = true;
      git.enable = true;
      keebs.enable = true;
      kitty.enable = true;
      nvim.enable = true;
      obs.enable = true;
      starship.enable = true;
      swappy.enable = true;
      tmux.enable = true;
    };

    services = {
      btrfs.enable = true;
      # easyeffects.enable = true;
      pipewire.enable = true;
      ssh.enable = true;
    };
  };

  programs = { nix-ld.enable = true; };

  services = {
    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    blueman = { enable = true; };
    logind = { lidSwitch = "suspend"; };
  };

  wm = {
    gnome.enable = true;
    # hyprland.enable = true;
    swayfx.enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
