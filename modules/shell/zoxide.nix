{ ... }:
{
  flake.modules.homeManager.zoxide =
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
