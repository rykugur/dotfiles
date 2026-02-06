{ self, ... }:
{
  flake.nixosModules.zoxide =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.zoxide ];
    };

  flake.homeModules.zoxide =
    { config, ... }:
    {
      programs.zoxide = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };
    };
}
