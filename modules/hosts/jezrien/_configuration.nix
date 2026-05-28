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
    ./_hardware-configuration.nix

    # ./_hyprland-config.nix
    ./_niri-config.nix
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
    substituters = [ "https://helix.cachix.org" ];
    trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
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
      # services.${username}.enableGnomeKeyring = true;
      u2f = {
        enable = true;
        settings = {
          cue = true;
        };
      };
      services.polkit-1.u2fAuth = true;
    };
    polkit.enable = true;
  };

  networking = {
    hostName = hostname;
  };

  environment = {
    systemPackages = with pkgs; [
      nfs-utils
      via
      vial
      vulkan-tools
    ];

    variables = {
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };

  # chaotic-nyx mesa_git: staged but DISABLED for now.
  # The Crimson Desert RDNA4 page-fault fix is not yet in mesa main (MR !41851,
  # still on Samuel Pitoiset's branch as of last check). Flip to `true` once that
  # MR merges to mesa main AND chaotic has rebuilt mesa_git past it, to front-run
  # nixpkgs and get the fix early.
  # TODO: once the fix reaches nixpkgs-unstable's mesa, remove chaotic.mesa-git
  # entirely (drop this option + the flake input):
  # https://gitlab.freedesktop.org/hakzsam/mesa/-/commit/113705d3abbc29404fe8e9f0385158b8e9f7755e
  chaotic.mesa-git.enable = false;

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
    dankMaterialShell.screenshotBackend = "swappy";
    pipewire = {
      quantum = 256;
      noiseSuppression.enable = false;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
