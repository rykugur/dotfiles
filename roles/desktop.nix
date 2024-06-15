{ config, lib, pkgs, ... }:
let cfg = config.roles.desktop;
in {
  options.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable { };
}
