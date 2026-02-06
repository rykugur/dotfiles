{ self, ... }:
{
  flake.nixosModules.lutris =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.lutris ];
    };

  flake.homeModules.lutris =
    { osConfig, pkgs, ... }:
    {
      home.packages = with pkgs; [ umu-launcher ];

      programs.lutris = {
        enable = true;

        extraPackages = with pkgs; [
          mangohud
          winetricks
          gamescope
          gamemode
          umu-launcher
          wmctrl
        ];

        steamPackage = osConfig.programs.steam.package;
        protonPackages = [ pkgs.proton-ge-bin ];
        winePackages = [ pkgs.wineWowPackages.stagingFull ];

      };

      # force lutris to use nixpkgs umu-launcher
      home.file = {
        ".local/share/lutris/runtime/umu/umu-run" = {
          source = "${pkgs.umu-launcher}/bin/umu-run";
          force = true;
        };
      };
    };
}
