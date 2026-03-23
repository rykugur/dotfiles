{ ... }:
{
  flake.modules.homeManager.direnv =
    { config, ... }:
    {
      programs.direnv = {
        enable = true;

        nix-direnv.enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
      };
    };
}
