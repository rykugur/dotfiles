{
  inputs,
  self,
  ...
}:
{
  flake = {
    nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.meta
        self.nixosModules.jezrien-config

        {
          nixpkgs = {
            overlays = [ self.overlays.default ];
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "electron-25.9.0"
                "nexusmods-app-unfree-0.21.1"
              ];
            };
          };
        }
      ];
    };

    nixosModules = {
      jezrien-config =
        { config, ... }:
        let
          metaCfg = config.meta.ryk;
        in
        {
          imports = [
            self.nixosModules.jezrien-hardware
            ./_configuration.nix

            inputs.stylix.nixosModules.stylix

            self.nixosModules.home-manager

            self.nixosModules.fonts
            self.nixosModules.stylix

            self.nixosModules.niri
            self.nixosModules.dank-material-shell

            self.nixosModules._1password
            self.nixosModules._3dp
            self.nixosModules.appimage
            self.nixosModules.atuin
            # self.nixosModules.audiorelay
            self.nixosModules.bat
            self.nixosModules.btop
            self.nixosModules.btrfs
            self.nixosModules.carapace
            self.nixosModules.direnv
            self.nixosModules.ghostty
            self.nixosModules.helix
            self.nixosModules.homelab
            self.nixosModules.git
            self.nixosModules.jackify
            self.nixosModules.jujutsu
            self.nixosModules.keebs
            self.nixosModules.nushell
            self.nixosModules.pipewire
            self.nixosModules.razer
            self.nixosModules.ssh
            self.nixosModules.starship
            self.nixosModules.swappy
            self.nixosModules.winboat
            self.nixosModules.yaak
            self.nixosModules.yazi
            self.nixosModules.zellij
            self.nixosModules.zen-browser
            self.nixosModules.zoxide
            self.nixosModules.zsa

            self.nixosModules.discord
            self.nixosModules.gamemode
            self.nixosModules.lutris
            self.nixosModules.nexus-mods
            self.nixosModules.obs-studio
            self.nixosModules.steam

            self.nixosModules.eve-online
            self.nixosModules.star-citizen
            # self.nixosModules.starsector
          ];

          meta.ryk = {
            username = "dusty";
            hostname = "jezrien";
          };

          ryk = {
            pipewire.quantum = 256;
          };

          home-manager.users.${metaCfg.username} = {
            imports = [
              self.homeModules.sops
              ./_home-packages.nix

              self.homeModules.jezrien-home-config
            ];
          };
        };

      jezrien-hardware =
        { ... }:
        {
          imports = [
            ./_hardware-configuration.nix
          ]
          ++ (with inputs.nixos-hardware.nixosModules; [
            common-pc
            common-pc-ssd
            common-cpu-amd
            common-gpu-amd
          ]);
        };
    };

    homeModules.jezrien-home-config =
      { ... }:
      {
        imports = [
          # ./_hyprland-cfg.nix
          ./_niri-cfg.nix
        ];

        ryk.dank-material-shell.screenshotBackend = "swappy";
        ryk.ghostty.hideWindowDecoration = true;
      };
  };
}
