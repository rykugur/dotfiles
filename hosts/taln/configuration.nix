{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  imports =
    [
      ./hardware-configuration.nix

      outputs.nixosModules.base

      outputs.nixosModules.btrfs

      outputs.nixosModules.pipewire
      inputs.nix-gaming.nixosModules.pipewireLowLatency

      outputs.nixosModules.gnome
      outputs.nixosModules.hyprland
      outputs.nixosModules.ssh

      outputs.nixosModules._1password
      outputs.nixosModules.gaming
    ] ++ (with inputs.nixos-hardware.nixosModules; [
      common-pc
      common-pc-ssd
      common-cpu-intel
      common-gpu-nvidia
    ]);

  hardware = {
    cpu.intel.updateMicrocode = true;

    nvidia = {
      modesetting.enable = true; #required

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
      users = [ "dusty" ];
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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  security = {
    pam = {
      u2f = {
        enable = true;
      };
    };
  };

  networking = {
    hostName = "taln";
    networkmanager.enable = true;
    search = [ "pihole.lan" "pihole" "8.8.8.8" "8.8.4.4" ];
  };

  services = {
    blueman = {
      enable = true;
    };

    logind = {
      lidSwitch = "suspend";
    };

    printing.enable = true;

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
    };
    gvfs.enable = true;

    xserver = {
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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
    nixPath = [ "/etc/nix/path" ];

    optimise.automatic = true;

    registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  programs.fish = {
    enable = true;
    vendor.functions.enable = true;
  };

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    home-manager
    neovim
  ] ++ [
    (import ../../scripts/nvidia-offload.nix { inherit pkgs; })
    (import ../../scripts/hyprland-suspend.nix { inherit pkgs; })
  ];

  users.users = {
    dusty = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/dusty";
      extraGroups = [ "wheel" "networkmanager" "openrazer" ];
      shell = pkgs.fish;
    };
  };

  time.timeZone = "America/Chicago";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
