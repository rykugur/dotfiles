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
          extraSpecialArgs = {
            inherit inputs;
            outputs = inputs.self;
            hostname = "taln";
            username = "dusty";
          };
          backupFileExtension = "bak";

          users.${username} = { pkgs, ... }: {
            imports =
              [ ../../../home ]
              ++ (with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ccstatusline
                claude-code
                homelab
                nushell
                opencode
                ssh
                television
              ]);

            home.packages = with pkgs; [
              nh
              nix-prefetch-scripts
              _1password-cli
              fd
              tldr
            ];

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
