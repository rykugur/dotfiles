{ config, lib, pkgs, ... }:
let cfg = config.rhx.hyprland.waybar;
in { config = lib.mkIf cfg.enable { }; }
