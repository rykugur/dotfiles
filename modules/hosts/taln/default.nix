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
      self.modules.darwin.dusty-nfs

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
            { config, pkgs, ... }:
            {
              imports = with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ai-common
                claude-code
                codex
                herdr
                homelab
                shell
                obsidian
                opencode
                oh-my-pi
                sops
                ssh
                eve-frontier
                starsector
                superfile
                television
              ];

              # Reaches hoid over the tailnet when away: homelab-0 advertises
              # 10.3.10.0/24, so no second tailnet node is needed on hoid.
              # Broker mode bypasses the local credential store, so a cold
              # start with neither LAN nor tailnet fails closed.
              sops.secrets.omp_auth_broker_token = {
                sopsFile = ./secrets.yaml;
                path = "${config.home.homeDirectory}/.omp/auth-broker.token";
                mode = "0400";
              };
              ryk.omp.broker.url = "https://hoid.local.ryk.sh:8765";

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
