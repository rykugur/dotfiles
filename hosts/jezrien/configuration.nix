{ inputs, outputs, lib, config, pkgs, hostname, username, ... }: {
  imports = [
    ../default.nix

    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.nixosModules
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
    kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
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
    # nameservers = [ "10.3.8.203" ];
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
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    systemPackages = with pkgs; [ polkit_gnome via vial ];

    variables = {
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };

  hardware.graphics = {
    extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
    extraPackages32 = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
  };

  programs = {
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
    };
    nix-ld = { enable = true; };
    # seahorse.enable = true;
  };

  services = {
    journald.storage = "volatile"; # potentially fix long boot times?

    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    xserver = {
      enable = true;
      displayManager.startx.enable = true;

      windowManager.openbox.enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    udev = {
      enable = true;
      packages = [ pkgs.via pkgs.vial ];
      extraRules = ''
        # Wooting One Legacy
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"

        # Wooting One update mode
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess"

        # Wooting Two Legacy
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"

        # Wooting Two update mode
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess"

        # Generic Wootings
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="31e3", TAG+="uaccess"

        # Disable KT_USB_AUDIO device
        ACTION=="add", ATTR{idVendor}=="31b2", ATTR{idProduct}=="0011", OPTIONS+="ignore_device"
      '';
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

  ### custom module stuff
  #
  rhx = {
    _1password.enable = true;
    btrfs.enable = true;
    fonts.enable = true;
    gamemode.enable = true;
    hyprland.enable = true;
    pipewire.enable = true;
    ssh.enable = true;
    steam.enable = true;
    virtman.enable = true;
    vr.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ../../users/${username}/home.nix; };
    backupFileExtension = "bak";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
