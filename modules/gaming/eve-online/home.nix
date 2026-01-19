{
  lib,
  nixosConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf nixosConfig.ryk.gaming.eve-online.enable {
    home.packages = with pkgs; [
      pyfa
      # rift-intel-tool
    ];
  };
}
