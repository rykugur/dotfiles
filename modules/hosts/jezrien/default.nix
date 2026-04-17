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
in
{
  flake.nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # TODO: migrate desktop legacy modules to dendritic
      ../../../legacy-modules/desktop

      self.modules.nixos.nix-defaults
      self.modules.nixos.ssh

      ./_configuration.nix

      inputs.home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix

      self.modules.nixos.meta
      self.modules.nixos.fonts
      self.modules.nixos.stylix

      self.modules.nixos.pipewire
      self.modules.nixos.starcitizen

      self.modules.nixos._1password
      self.modules.nixos.btrfs
      self.modules.nixos.zsa
      self.modules.nixos.razer
      self.modules.nixos.obs-studio
      self.modules.nixos.gamemode
      self.modules.nixos.steam
      self.modules.nixos.appimage

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

                # individual modules
                btop
                ai-common
                claude-code
                codex
                espanso
                eve-online
                homelab
                jackify
                keebs
                nexus-mods
                nushell
                opencode
                sops
                starsector
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
                xrandr
                xbacklight

                # misc gaming
                dolphin-emu

                affine
                baobab
                bottom
                fastfetch
                fd
                file
                file-roller
                kalker
                minder
                mousai
                nemo
                nitch
                obsidian
                pavucontrol
                playerctl
                rcon-cli
                seahorse
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

              gtk.gtk4.theme = null;

              programs.ghostty.settings.window-decoration = "none";

              xdg.configFile."noisetorch/config.toml".text = ''
                Threshold = 70
                DisplayMonitorSources = false
                EnableUpdates = true
                FilterInput = true
                FilterOutput = false
                LastUsedInput = "alsa_input.usb-Elgato_Systems_Elgato_Wave_3_BS14M1A01945-00.mono-fallback"
                LastUsedOutput = ""
              '';

              xdg.enable = true;
              programs.home-manager.enable = true;

              systemd.user.startServices = "sd-switch";

              home.stateVersion = "23.11";
            };
        };
      }
    ];
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
}
