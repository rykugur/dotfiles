{ ... }:
{
  flake.modules.homeManager.yazi =
    { config, ... }:
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };
    };
}
