# Taln — macOS (aarch64-darwin)
{
  inputs,
  self,
  ...
}:
{
  flake.darwinConfigurations.taln = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      ../../legacy-modules/darwin

      ../../hosts/taln/configuration.nix

      inputs.stylix.darwinModules.stylix

      self.modules.darwin.fonts
      self.modules.darwin.stylix
    ];
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      hostname = "taln";
      username = "dusty";
    };
  };
}
