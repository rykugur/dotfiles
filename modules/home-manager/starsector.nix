{ config, pkgs, ... }: {
  home = {
    packages = [
      pkgs.starsector
    ];
  };
}
