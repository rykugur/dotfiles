{ lib, pkgs, nixosConfig, ... }: {
  config = lib.mkIf nixosConfig.rhx.audiorelay.enable {
    home.packages = [ pkgs.audiorelay ];
  };
}
