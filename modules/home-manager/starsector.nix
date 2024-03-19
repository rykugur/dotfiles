{ config, pkgs, ... }:
let
  modsDrv = with pkgs.starsectorMods.starsectorMods; mkModDirDrv [
    lazylib
    magiclib
    nexerelin
    zz_graphicslib
  ];
in
{
  home = {
    packages = [
      pkgs.starsector
    ];

    file = {
      ".local/share/starsector/mods/lazylib" = {
        source = "${pkgs.starsectorMods.starsectorMods.lazylib}";
      };
      ".local/share/starsector/mods/magiclib" = {
        source = "${pkgs.starsectorMods.starsectorMods.magiclib}";
      };
      ".local/share/starsector/mods/nexerelin" = {
        source = "${pkgs.starsectorMods.starsectorMods.nexerelin}";
      };
      ".local/share/starsector/mods/zz_graphicslib" = {
        source = "${pkgs.starsectorMods.starsectorMods.zz_graphicslib}";
      };
    };
  };
}
