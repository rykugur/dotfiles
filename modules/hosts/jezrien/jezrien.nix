{
  inputs,
  self,
  ...
}:
{
  flake = {
    nixosModules = {
      jezrien-config =
        { ... }:
        {
          imports = [
            # TODO: refactor these into modules
            ./_configuration.nix

            inputs.stylix.nixosModules.stylix

            self.nixosModules.home-manager-common

            self.nixosModules.helix
          ];

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
