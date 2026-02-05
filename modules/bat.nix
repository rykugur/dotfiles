{ self, ... }:
{
  flake.nixosModules.bat =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.bat ];
    };

  flake.homeModules.bat =
    { pkgs, ... }:
    {
      programs.bat = {
        enable = true;

        extraPackages = with pkgs.bat-extras; [
          batdiff
          batman
          batgrep
          batwatch
        ];
      };
    };
}
