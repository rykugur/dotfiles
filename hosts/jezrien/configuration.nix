{ inputs, outputs, pkgs, hostname, username, ... }: {
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-amd
  ]);

  # TODO: find a better spot for this
  nix.settings = { trusted-users = [ "root" "@wheel" ]; };

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

  networking = {
    hostName = hostname;
    # networkmanager = {
    #   enable = true;
    # dns = "none";
    # insertNameservers = [ "10.3.8.250" ];
    # };

    # useDHCP = false;
    # dhcpcd.enable = false;
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
      extraPackages = with pkgs; [ libva-vdpau-driver libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ libva-vdpau-driver libvdpau-va-gl ];
    };

    keyboard.qmk.enable = true;

    xone.enable = true;
  };

  programs = {
    corectrl = { enable = true; };
    dconf.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 5";
      # flake = "/home/${username}/.dotfiles/flake.nix";
    };

    nix-ld = { enable = true; };
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
      extraGroups = [ "wheel" "plugdev" "networkmanager" "corectrl" ];
    };
  };

  ### custom module stuff
  rhx = {
    keyboardVendor = "zsa";

    roles = {
      _3dp.enable = true;
      desktop.enable = true; # also enables dev and terminal roles
      gaming.enable = true;
      # virtualization.enable = true;
    };

    btrfs.enable = true;
    niri = {
      enable = true;
      bar = "dankMaterialShell";
      screenshotBackend = "swappy";
      monitors = {
        "DP-1" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 174.963;
          };
          position = {
            x = 0;
            y = 1440;
          };
          variable-refresh-rate = "on-demand";
          focus-at-startup = true;
        };
        "DP-2" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 144.0;
          };
          position = {
            x = 0;
            y = 0;
          };
          variable-refresh-rate = "on-demand";
        };
      };
    };
    razer.enable = true;
    starcitizen.enable = true;
    stylix.enable = true;
    winboat.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
