{
  config,
  pkgs,
  ...
}:
let
  metaCfg = config.meta.ryk;
in
{
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
      services.${metaCfg.username}.enableGnomeKeyring = true;
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
    hostName = metaCfg.hostname;
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
      clean.extraArgs = "--keep-since 21d --keep 5";
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

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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

  users.users = {
    ${metaCfg.username} = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/${metaCfg.username}";
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
