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
      inputs.chaotic.nixosModules.default

      self.modules.nixos.meta
      self.modules.nixos.fonts
      self.modules.nixos.stylix

      self.modules.nixos.pipewire
      # disabled: nix-gaming dxvk strictDeps/structuredAttrs regression breaks
      # rsi-launcher eval (cross-spliced through wineprefix-preparer).
      # starcitizen-lite below provides the LUG prereqs without the broken
      # launcher path; re-enable this once upstream nix-gaming is fixed.
      # self.modules.nixos.starcitizen
      self.modules.nixos.starcitizen-lite

      self.modules.nixos._1password
      self.modules.nixos.btrfs
      self.modules.nixos.dusty-nfs
      self.modules.nixos.zsa

      self.modules.nixos.docker
      self.modules.nixos.winboat

      self.modules.nixos.appimage
      self.modules.nixos.gamemode
      self.modules.nixos.obs-studio
      self.modules.nixos.razer
      self.modules.nixos.steam

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
                grok
                opencode
                pi

                # individual modules
                btop
                espanso
                eve-online
                easyeffects
                homelab
                jackify
                keebs
                nushell
                obsidian
                # sesh
                sops
                starsector
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

              home.sessionVariables = {
                GDK_BACKEND = "wayland";
              };

              programs.ghostty.settings.window-decoration = "none";

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
