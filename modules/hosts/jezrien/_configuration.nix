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
  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
    # Declared here rather than relying on the flake's nixConfig: that path
    # needs a per-user prompt whose answer is cached against the exact
    # substituter list, so any change to the set silently falls back to
    # "ignoring untrusted flake configuration setting" under a non-interactive
    # nixos-rebuild, and the caches go unused.
    substituters = [
      "https://helix.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;

    # RTL8125 2.5GbE NIC: use Realtek's vendor r8125 driver instead of the
    # in-kernel r8169. r8169 leaves hardware offloads disabled (rx-gro-hw fixed
    # off, sg/tso off) and can't absorb packet reordering on some upstream paths,
    # which throttles parallel downloads — Steam/Valve capped ~20 Mbps here while
    # a Windows box on the same LAN hit ~900. See Arcanum [[Slow Steam Downloads]].
    extraModulePackages = [ config.boot.kernelPackages.r8125 ];
    blacklistedKernelModules = [ "r8169" ];

    loader = {
      systemd-boot = {
        enable = true;
        extraEntries."windows.conf" = ''
          title Windows
          efi /EFI/Microsoft/Boot/bootmgfw.efi
          sort-key z_windows
        '';
        extraInstallCommands = ''
          win_esp=$(${pkgs.coreutils}/bin/mktemp -d)
          cleanup() {
            ${pkgs.util-linux}/bin/umount "$win_esp" >/dev/null 2>&1 || true
            ${pkgs.coreutils}/bin/rmdir "$win_esp" >/dev/null 2>&1 || true
          }
          trap cleanup EXIT
          ${pkgs.util-linux}/bin/mount -o ro,umask=077 /dev/disk/by-partuuid/05e33b02-f15d-4d8f-9bb8-33771103bb79 "$win_esp"
          ${pkgs.coreutils}/bin/mkdir -p ${config.boot.loader.efi.efiSysMountPoint}/EFI
          ${pkgs.coreutils}/bin/rm -rf ${config.boot.loader.efi.efiSysMountPoint}/EFI/Microsoft
          ${pkgs.coreutils}/bin/cp -a "$win_esp/EFI/Microsoft" ${config.boot.loader.efi.efiSysMountPoint}/EFI/
        '';
      };
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

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
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

    udev = {
      enable = true;
      extraRules = ''
        # Disable KT_USB_AUDIO device
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="31b2", ATTR{idProduct}=="0011", ATTR{authorized}="0"
      '';
    };
  };

  # A detached OMP process can keep a Ghostty scope stopping for the 90s default.
  systemd.user.settings.Manager.DefaultTimeoutStopSec = "30s";

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

  # Keep the desktop responsive during memory-heavy local builds.
  #
  # max-jobs = 1 never bounded this: a single derivation with cores = 8 is what
  # produced the 64 GB link-time spikes, and the daemon cgroup had no ceiling at
  # all. cores = 4 halves per-derivation link parallelism (the actual memory
  # source) and the cgroup limits below cap every concurrent build together, so
  # a runaway build now dies instead of swapping the machine to death. That
  # makes 4 jobs safer than the old single unbounded one.
  nix.settings = {
    max-jobs = 4; # 4 x 4 = 16 of 24 threads; 8 left for the session
    cores = 4;
    max-substitution-jobs = 8; # default 16; vasher saw a 7.1 GiB substituter
  };

  nix.daemonCPUSchedPolicy = "batch";
  nix.daemonIOSchedClass = "idle";

  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "40G"; # throttle and reclaim into zram, no kill
    MemoryMax = "52G"; # hard ceiling; kills the build, not the desktop
    CPUWeight = 20; # the session sits at the 100 default and wins contention
    IOWeight = 20;
  };

  ### custom module stuff
  ryk = {
    dankMaterialShell.screenshotBackend = "swappy";
    pipewire = {
      quantum = 256;
      noiseSuppression.enable = false;
    };
    # btrfs root is mounted compress=zstd, and swapfiles can't live on a
    # compressed subvol. 64GB RAM + 16GB zram is plenty without a backing file.
    zram.swapfileSize = 0;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
