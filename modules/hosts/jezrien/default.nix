# Jezrien — NixOS desktop (x86_64-linux)
{
  config,
  inputs,
  self,
  ...
}:
let
  # TODO: this can be removed once all modules are migrated
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
  mkJezrien =
    extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        # WM: niri (hyprland lives at self.modules.nixos.hyprland)
        self.modules.nixos.niri
        self.modules.nixos.dank-material-shell

        self.modules.nixos.nix-defaults
        # Vasher is down pending a rebuild (2026-10-28); re-add
        # self.modules.nixos.vasher-cache once it serves again. An unreachable
        # substituter costs ~10-20s of curl retries per narinfo miss.
        self.modules.nixos.ssh
        self.modules.nixos.helix-root
        ./_configuration.nix

        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix

        self.modules.nixos.meta
        self.modules.nixos.fonts
        self.modules.nixos.login-shell
        self.modules.nixos.stylix

        self.modules.nixos.pipewire
        self.modules.nixos.starcitizen

        self.modules.nixos._1password
        self.modules.nixos.btrfs
        self.modules.nixos.dusty-nfs
        self.modules.nixos.zram
        self.modules.nixos.zsa

        self.modules.nixos.docker
        self.modules.nixos.winboat

        # self.modules.nixos.vfio
        # {
        #   ryk.vfio = {
        #     enable = true;
        #     domainName = "windows-vm";
        #     gpu = {
        #       pciAddress = "0000:2f:00.0";
        #       linuxDriver = "amdgpu";
        #     };
        #     audio = {
        #       pciAddress = "0000:2f:00.1";
        #       linuxDriver = "snd_hda_intel";
        #     };
        #     memoryMiB = 32768;
        #     vcpus = 16;
        #     diskSizeGiB = 500;
        #     usbDevices = [
        #       {
        #         name = "Xbox Wireless Adapter";
        #         vendorId = "045e";
        #         productId = "02fe";
        #       }
        #       {
        #         name = "VIRPIL left stick";
        #         vendorId = "3344";
        #         productId = "8384";
        #       }
        #       {
        #         name = "VIRPIL right stick";
        #         vendorId = "3344";
        #         productId = "4384";
        #       }
        #       {
        #         name = "ZSA Moonlander";
        #         vendorId = "3297";
        #         productId = "1969";
        #       }
        #       {
        #         name = "Razer Naga V2 Pro";
        #         vendorId = "1532";
        #         productId = "00a8";
        #       }
        #     ];
        #   };
        # }

        self.modules.nixos.audiorelay
        self.modules.nixos.appimage
        self.modules.nixos.gamemode
        self.modules.nixos.ntsync
        self.modules.nixos.obs-studio
        self.modules.nixos.razer
        self.modules.nixos.steam
        self.modules.nixos.gaming

        # home-manager config
        {
          home-manager = {
            useGlobalPkgs = true;
            extraSpecialArgs = {
              inherit
                inputs
                username
                ;
              outputs = inputs.self;
              hostname = "jezrien";
            };
            backupFileExtension = "bak";

            users.${username} =
              { pkgs, ... }:
              {
                imports = with hmModules; [
                  # groups
                  developer
                  gaming
                  _3dp

                  # ai stuff
                  ai-common
                  claude-code
                  codex
                  herdr
                  zed-editor
                  oh-my-pi

                  # individual modules
                  btop
                  bottom
                  htop
                  gtk
                  eve-online
                  easyeffects
                  homelab
                  jackify
                  keebs
                  obsidian
                  # sesh
                  sops
                  starsector
                  superfile
                  wow
                  eve-frontier
                  swappy
                  television
                  wezterm
                  zen-browser
                ];

                sops.secrets = {
                  homelab_ssh_private_key = {
                    sopsFile = ./secrets.yaml;
                  };
                };


                home.packages = with pkgs; [
                  # nix
                  nix-prefetch-scripts
                  nixd
                  nix-index

                  # fonts
                  font-awesome

                  # desktop
                  arandr
                  cliphist
                  pinta
                  xrandr
                  xbacklight

                  # misc gaming
                  dolphin-emu
                  faugus-launcher # lutris alternative

                  affine
                  baobab
                  bottom
                  fastfetch
                  fd
                  file
                  kalker
                  minder
                  mousai
                  nitch
                  pavucontrol
                  playerctl
                  rcon-cli
                  seahorse
                  spotifast
                  spotify
                  sshfs
                  tigervnc
                  tldr
                  vlc
                  xdg-utils
                  zenity

                  yt-dlg
                  yt-dlp

                  amdgpu_top
                  radeontop

                  feh
                  ristretto

                  libtool

                  telegram-desktop

                  google-chrome

                ];

                home.sessionVariables = {
                  GDK_BACKEND = "wayland";
                  PROTON_USE_NTSYNC = "1";
                  PROTON_NO_ESYNC = "1";
                  PROTON_NO_FSYNC = "1";
                };

                programs.ghostty.settings.window-decoration = "none";

                xdg.enable = true;
                programs.home-manager.enable = true;

                systemd.user.startServices = "sd-switch";

                home.stateVersion = "23.11";
              };
          };
        }
      ]
      ++ extraModules;
      specialArgs = {
        inherit
          inputs
          # TODO: this can be removed once all modules are migrated
          username
          ;
        outputs = inputs.self;
        hostname = "jezrien";
      };
    };
in
{
  flake.nixosConfigurations = {
    jezrien = mkJezrien [ ];
    jezrien-prebuild = mkJezrien [ ];
  };
}
