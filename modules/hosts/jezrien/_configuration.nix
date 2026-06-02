{
  inputs,
  outputs,
  pkgs,
  hostname,
  username,
  config,
  lib,
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

  # chaotic-nyx mesa_git: TEMPORARY workaround for the Crimson Desert RDNA4 GPU
  # page-fault (vkd3d-proton#3058, mesa MR !41851).
  #
  # Lifecycle:
  #   * ~/check-chaotic-mesa-crimson.sh → ✅  flip enable below to `true`
  #   * ~/check-nixpkgs-mesa-crimson.sh → ✅  drop chaotic entirely (see TODO)
  #
  # TODO: once nixos-unstable's stock mesa carries the fix, remove this whole
  # block, the inputs.chaotic.nixosModules.default import in default.nix, the
  # chaotic input from flake.nix, and the nyx-cache substituter + key from
  # flake.nix nixConfig. The `warnings` block below will keep nagging on every
  # rebuild until this is cleaned up.
  chaotic.mesa-git.enable = true;
  warnings = lib.optionals config.chaotic.mesa-git.enable [
    ''
      chaotic.mesa-git is a TEMPORARY workaround (Crimson Desert RDNA4 fix,
      vkd3d-proton#3058 / mesa MR !41851). Run ~/check-nixpkgs-mesa-crimson.sh
      periodically; when it returns ✅, follow its cleanup steps to drop
      chaotic and revert to stock mesa.
    ''
  ];

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
