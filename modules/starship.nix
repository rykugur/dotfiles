{ self, ... }:
{
  flake.nixosModules.starship =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.starship ];
    };

  flake.homeModules.starship =
    { config, ... }:
    {
      programs.starship = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;

        settings = {
          hostname = {
            ssh_symbol = "";
          };
          nix_shell = {
            format = "[$name]($style)";
            heuristic = true;
          };
          kubernetes = {
            disabled = false;
            detect_env_vars = [
              "K8S"
              "HOMELAB"
            ];
          };
        };
      };
    };
}
