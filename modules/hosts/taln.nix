# Taln — macOS (aarch64-darwin)
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
  flake.darwinConfigurations.taln = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      ../../hosts/taln/configuration.nix

      inputs.stylix.darwinModules.stylix

      self.modules.darwin.fonts
      self.modules.darwin.stylix
      self.modules.darwin.aerospace

      # Dendritic homeManager modules
      {
        home-manager.users.${username}.imports = with hmModules; [
          carapace
          ccstatusline
          direnv
          ghostty
          git
          helix
          homelab
          jujutsu
          nushell
          opencode
          ssh
          starship
          television
          yazi
          zellij
          zoxide
        ];
      }
    ];
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      hostname = "taln";
      username = "dusty";
    };
  };
}
