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
      ../../../legacy-modules/nixos
      ../../../legacy-modules

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

      # home-manager config
      {
        home-manager = {
          extraSpecialArgs = {
            inherit
              inputs
              username
              ;
            outputs = inputs.self;
            hostname = "jezrien";
          };
          backupFileExtension = "bak";

          users.${username} = { pkgs, ... }: {
            imports =
              [ ../../../home ]
              ++ (with hmModules; [
                # groups
                developer
                gaming
                _3dp

                # individual modules
                btop
                ccstatusline
                claude-code
                espanso
                eve-online
                homelab
                keebs
                nushell
                opencode
                starsector
                swappy
                television
                wezterm
                zen-browser
              ]);

            nixpkgs.config.permittedInsecurePackages = [
              "electron-25.9.0"
              "nexusmods-app-unfree-0.21.1"
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

              nwg-look
              catppuccin-gtk
              catppuccin-cursors
              catppuccin-papirus-folders

              affine
              baobab
              bottom
              fastfetch
              fd
              file
              file-roller
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

              beyond-all-reason
              kalker
            ];

            programs.ghostty.settings.window-decoration = "none";
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
