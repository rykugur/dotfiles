{ self, ... }:
{
  flake.nixosModules.direnv =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.direnv ];
    };

  flake.homeModules.direnv =
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
