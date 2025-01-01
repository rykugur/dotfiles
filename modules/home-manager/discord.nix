{ config, lib, pkgs, ... }:
let cfg = config.rhx.discord;
in {
  options.rhx.discord = {
    enable = lib.mkEnableOption "Enable discord home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.discord pkgs.betterdiscordctl ];
  };
}
