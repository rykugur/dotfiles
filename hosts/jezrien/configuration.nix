{ inputs, outputs, pkgs, hostname, username, ... }: {
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager

    outputs.nixosModules

    ../../roles
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
    # networkmanager = {
    #   enable = true;
    # dns = "none";
    # insertNameservers = [ "10.3.8.250" ];
    # };

    # useDHCP = false;
    # dhcpcd.enable = false;
  };

  environment = {
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
    dconf.enable = true;
    nix-ld = { enable = true; };
    # seahorse.enable = true;
  };

  services = {
    journald.storage = "volatile"; # potentially fix long boot times?

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
  rhx = {
    roles = {
      _3dp.enable = true;
      desktop.enable = true; # also enables dev and terminal roles
      gaming.enable = true;
      virtualization.enable = true;
      # vr.enable = true;
    };

    btrfs.enable = true;
    #starcitizen.enable = true;
    vr.enable = true;
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
