{ config, lib, pkgs, ... }:
let cfg = config.ryk.discord;
in {
  options.ryk.discord = {
    enable = lib.mkEnableOption "Enable discord home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.discord pkgs.betterdiscordctl ];
  };
}
