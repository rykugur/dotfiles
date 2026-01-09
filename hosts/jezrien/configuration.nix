{
  inputs,
  outputs,
  pkgs,
  hostname,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    ./hyprland-config.nix
    ./niri-config.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-amd
  ]);

  # TODO: find a better spot for this
  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
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
        settings = {
          cue = true;
        };
      };
    };
    polkit.enable = true;
  };

  networking = {
    hostName = hostname;
  };

  environment = {
    systemPackages = with pkgs; [
      nfs-utils
      polkit_gnome
      via
      vial
      vulkan-tools
    ];

    variables = {
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };

  hardware = {
    amdgpu.overdrive.enable = true;

    graphics = {
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    keyboard.qmk.enable = true;

    xone.enable = true;
  };

  programs = {
    corectrl = {
      enable = true;
    };
    dconf.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 5";
      # flake = "/home/${username}/.dotfiles/flake.nix";
    };

    nix-ld = {
      enable = true;
    };
  };

  services = {
    flatpak.enable = true;

    printing.enable = true;

    gvfs.enable = true;

    xserver = {
      enable = true;
      displayManager.startx.enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    udev = {
      enable = true;
      extraRules = ''
        # Disable KT_USB_AUDIO device
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="31b2", ATTR{idProduct}=="0011", ATTR{authorized}="0"
      '';
    };
  };

  users.users = {
    ${username} = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/${username}";
      extraGroups = [
        "input"
        "wheel"
        "plugdev"
        "networkmanager"
        "corectrl"
      ];
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  ### custom module stuff
  ryk = {
    keyboardVendor = "zsa";

    roles = {
      _3dp.enable = true;
      desktop.enable = true; # also enables dev and terminal roles
      gaming.enable = true;
      # virtualization.enable = true;
    };

    # audiorelay.enable = true;
    btrfs.enable = true;
    dankMaterialShell.screenshotBackend = "swappy";

    pipewire = {
      enable = true;
      quantum = 256;
    };
    razer.enable = true;
    stylix.enable = true;

    dev.enable = true;

    gaming = {
      eve-online.enable = true;
      nexus-mods.enable = true;
      starcitizen.enable = true;
    };
  };

  home-manager = {
    extraSpecialArgs = {
      inherit
        inputs
        outputs
        hostname
        username
        ;
    };
    users = {
      ${username} = import ./home.nix;
    };
    backupFileExtension = "bak";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
