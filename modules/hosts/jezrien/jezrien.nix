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
            # TODO: refactor these into modules
            ./_configuration.nix

            inputs.stylix.nixosModules.stylix

            self.nixosModules.home-manager

            self.nixosModules.helix
            self.nixosModules.ssh
          ];

          home-manager.users.${metaCfg.username} = {
            imports = [
              self.homeModules.sops
              ./_home-packages.nix
            ];

            # ryk = {
            #   btop.enable = true;
            #   keebs.enable = true;
            #   ghostty.hideWindowDecoration = true;
            #   starsector = {
            #     enable = true;
            #     mods.enable = true;
            #   };
            #   swappy.enable = true;
            # };
          };

          ### custom module stuff
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
  };
}
