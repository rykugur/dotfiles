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

            self.nixosModules.home-manager-common

            inputs.stylix.nixosModules.stylix
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
