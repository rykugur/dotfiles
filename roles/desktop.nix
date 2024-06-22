{ config, lib, pkgs, username, ... }:
let cfg = config.roles.desktop;
in {
  options.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { home.packages = with pkgs; [ bat ]; };
  };
}
