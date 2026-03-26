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
      ../../legacy-modules/nixos
      ../../legacy-modules

      self.modules.nixos.nix-defaults
      self.modules.nixos.ssh

      ../../hosts/jezrien

      inputs.stylix.nixosModules.stylix

      self.modules.nixos.meta
      self.modules.nixos.fonts
      self.modules.nixos.stylix

      self.modules.nixos.pipewire
      self.modules.nixos.starcitizen

      # Dendritic homeManager modules
      {
        home-manager.users.${username}.imports = with hmModules; [
          # groups
          developer
          gaming
          _3dp

          # individual modules
          btop
          ccstatusline
          claude-code
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
