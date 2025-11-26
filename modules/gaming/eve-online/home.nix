{ lib, nixosConfig, pkgs, ... }: {
  config = lib.mkIf nixosConfig.rhx.eve-online.enable {
    home.packages = with pkgs; [ pyfa ];
  };
}
