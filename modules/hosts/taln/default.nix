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
      ./_configuration.nix

      inputs.home-manager.darwinModules.home-manager
      inputs.stylix.darwinModules.stylix

      self.modules.darwin.fonts
      self.modules.darwin.stylix
      self.modules.darwin.aerospace

      # home-manager config
      {
        home-manager = {
          useGlobalPkgs = true;
          extraSpecialArgs = {
            inherit inputs;
            outputs = inputs.self;
            hostname = "taln";
            username = "dusty";
          };
          backupFileExtension = "bak";

          users.${username} =
            { pkgs, ... }:
            {
              imports = with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ai-common
                claude-code
                codex
                espanso
                homelab
                nushell
                opencode
                sops
                ssh
                television
              ];

              home.packages = with pkgs; [
                nh
                _1password-cli
                fd
                tldr
              ];

              xdg.enable = true;
              programs.home-manager.enable = true;

              home.stateVersion = "23.11";
            };
        };
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
