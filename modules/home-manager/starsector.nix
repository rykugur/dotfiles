{ config, pkgs, ... }:
{
  home = {
    packages = [
      pkgs.starsector

      pkgs.starsectorMods.lazylib
      pkgs.starsectorMods.magiclib
      pkgs.starsectorMods.nexerelin
      pkgs.starsectorMods.zz_graphicslib
    ];

    file = {
      ".local/share/starsector/mods/lazylib" = {
        source = "${pkgs.starsectorMods.lazylib}";
      };
      ".local/share/starsector/mods/magiclib" = {
        source = "${pkgs.starsectorMods.magiclib}";
      };
      ".local/share/starsector/mods/nexerelin" = {
        source = "${pkgs.starsectorMods.nexerelin}";
      };
      ".local/share/starsector/mods/zz_graphicslib" = {
        source = "${pkgs.starsectorMods.zz_graphicslib}";
      };
    };
  };
}
