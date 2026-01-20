{
  lib,
  nixosConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf nixosConfig.ryk.gaming.jackify.enable {

    home.packages = with pkgs; [
      jackify
    ];
  };
}
