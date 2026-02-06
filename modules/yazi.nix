{ self, ... }:
{
  flake.nixosModules.yazi =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.yazi ];
    };

  flake.homeModules.yazi =
    { config, ... }:
    {
      programs.yazi = {
        enable = true;
        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };
    };
}
