{ lib, nixosConfig, pkgs, ... }: {
  config = lib.mkIf nixosConfig.rhx.gaming.eve-online.enable {
    home.packages = with pkgs; [ pyfa ];
  };
}
