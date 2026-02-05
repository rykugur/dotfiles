{ inputs, self, ... }:
{
  flake.nixosModules.atuin =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.atuin ];
    };

  flake.homeModules.atuin =
    { config, pkgs, ... }:
    {
      programs.atuin = {
        enable = true;
        package = inputs.atuin.packages.${pkgs.stdenv.hostPlatform.system}.default;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;

        flags = [ "--disable-up-arrow" ];
      };
    };
}
