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
      ../../legacy-modules/base
      ../../legacy-modules/nixos
      ../../legacy-modules

      ../../roles

      ../../hosts/jezrien

      inputs.stylix.nixosModules.stylix

      self.modules.nixos.meta

      self.modules.nixos.starcitizen

      # Dendritic homeManager modules
      {
        home-manager.users.${username}.imports = with hmModules; [
          nushell
        ];
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
