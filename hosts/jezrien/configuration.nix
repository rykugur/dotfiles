{ inputs, outputs, lib, config, pkgs, hostname, username, roles, ... }: {
  imports = [
    ../default.nix

    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.nixosModules
    roles
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-amd
  ]);

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
    search = [ "router.lan" ];
    nameservers = [ "10.3.8.157" ];
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
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    systemPackages = with pkgs; [ polkit_gnome ];

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
    users = { ${username} = import ../../users/${username}/home.nix; };
    backupFileExtension = "bak";
  };

  hardware.graphics = {
    extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
    extraPackages32 = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
  };

  roles = {
    desktop.enable = true;
    dev.enable = true;
    gaming.enable = true;
  };

  modules = {
    gaming = {
      starcitizen.enable = true;
      starsector = {
        enable = true;
        mods.enable = true;
      };
      wow.enable = true;
      vfio = {
        enable = false; # maybe I'll muck with this some other time
        vfioIds = [ "1002:747e" "1002:ab30" ];
      };
    };

    programs = {
      _1password.enable = true;
      fish.enable = true;
      git.enable = true;
      keebs.enable = true;
      kitty.enable = true;
      nvim.enable = true;
      obs.enable = true;
      razer.enable = true;
      swappy.enable = true;
      tmux.enable = true;
      virtman.enable = true;
    };

    services = {
      btrfs.enable = true;
      easyeffects.enable = true;
      pipewire.enable = true;
      ssh.enable = true;
    };

    wm = { hyprland.enable = true; };
  };

  programs = {
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
    };
    nix-ld = { enable = true; };
    seahorse.enable = true;
  };

  services = {
    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    xserver = {
      enable = true;
      displayManager.startx.enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
