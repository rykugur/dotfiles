{ config, lib, pkgs, username, hostname, ... }:
let cfg = config.programs.waybarz;
in {
  options.programs.waybarz.enable = lib.mkEnableOption "enable waybar";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.waybar = {
        enable = true;
        package = pkgs.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      };
      home.file = {
        ".config/waybar/config.json" = {
          source = ../../hosts/${hostname}/waybar.conf;
        };
        ".config/waybar/style.css" = {
          source = ../../../configs/waybar/style.css;
        };
        ".config/waybar/themes" = {
          source = ../../../configs/waybar/themes;
          recursive = true;
        };
        ".config/waybar/launch.fish" = {
          source = ../../../configs/waybar/launch.fish;
          executable = true;
        };
      };
    };
  };
}
