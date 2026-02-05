{ self, ... }:
{
  flake.nixosModules.carapace =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.carapace ];
    };

  flake.homeModules.carapace =
    { config, ... }:
    {
      programs.carapace = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };
    };
}
