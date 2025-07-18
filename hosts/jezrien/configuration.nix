{ inputs, outputs, pkgs, hostname, username, ... }: {
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.baseModules
    outputs.nixosModules

    ../../roles
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-amd
  ]);

  # TODO: find a better spot for this
  nix.settings = {
    extra-substituters = [ "https://helix.cachix.org" ];
    extra-trusted-public-keys =
      [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];

    trusted-users = [ "root" "@wheel" ];
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
      extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
    };
  };

  programs = {
    corectrl = { enable = true; };
    dconf.enable = true;
    nix-ld = { enable = true; };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 3";
      # flake = "/home/${username}/.dotfiles/flake.nix";
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
      extraGroups = [ "wheel" "networkmanager" "corectrl" ];
    };
  };

  ### custom module stuff
  rhx = {
    roles = {
      _3dp.enable = true;
      desktop.enable = true; # also enables dev and terminal roles
      gaming.enable = true;
      virtualization.enable = true;
    };

    btrfs.enable = true;
    starcitizen.enable = true;
    wooting.enable = true;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ../../users/${username}/home.nix; };
    backupFileExtension = "bak";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
