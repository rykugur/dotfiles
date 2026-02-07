{
  inputs,
  self,
  ...
}:
{
  flake = {
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
            self.nixosModules.audiorelay

            self.nixosModules.niri
            self.nixosModules.dank-material-shell

            self.nixosModules._3dp
            self.nixosModules.helix
            self.nixosModules.ssh
          ];

          meta.ryk = {
            username = "dusty";
            hostname = "jezrien";
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
          ./_niri-cfg.nix
        ];
        # TODO: finish me
      };
  };
}

# modules to convert:
#

# desktop/
# hyprland/...
