# Jezrien — NixOS desktop (x86_64-linux)
{ config, inputs, ... }:
let
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
in {
  flake.nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ../../legacy-modules/base
      ../../legacy-modules/nixos
      ../../legacy-modules

      ../../roles

      ../../hosts/jezrien

      inputs.stylix.nixosModules.stylix

      # Dendritic homeManager modules
      {
        home-manager.users.${username}.imports = with hmModules; [
          nushell
        ];
      }
    ];
    specialArgs = {
      inherit inputs username;
      outputs = inputs.self;
      hostname = "jezrien";
    };
  };
}
