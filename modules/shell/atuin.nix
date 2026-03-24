{ ... }:
{
  flake.modules.homeManager.atuin =
    { config, pkgs, ... }:
    {
      programs.atuin = {
        enable = true;
        package = pkgs.atuin;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;

        flags = [ "--disable-up-arrow" ];
      };
    };
}
