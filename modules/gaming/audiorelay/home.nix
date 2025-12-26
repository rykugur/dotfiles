{ lib, pkgs, nixosConfig, ... }: {
  config = lib.mkIf nixosConfig.rhx.gaming.audiorelay.enable {
    home.packages = [ pkgs.audiorelay ];
  };
}
