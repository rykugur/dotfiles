{ lib, pkgs, nixosConfig, ... }: {
  config = lib.mkIf nixosConfig.ryk.gaming.audiorelay.enable {
    home.packages = [ pkgs.audiorelay ];
  };
}
