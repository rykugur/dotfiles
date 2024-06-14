{ config, lib, inputs, pkgs, username, hostname, ... }:
let cfg = config.wm.hyprland;
in {
  options.wm.hyprland.enable = lib.mkEnableOption "Enable hyprland.";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    xdg.portal = { enable = true; };

    # environment.systemPackages = with pkgs; [
    #   xdg-desktop-portal-gtk
    # ];

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        dunst
        libnotify
        grim
        grimblast
        hyprlock
        hyprpaper
        inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
        slurp
        swappy
        swayidle
        swaylock
        wlogout
      ];

      programs.fuzzel = {
        enable = true;
        settings = {
          colors = {
            background = "1e1e2edd";
            text = "cdd6f4ff";
            match = "f38ba8ff";
            selection = "585b70ff";
            selection-match = "f38ba8ff";
            selection-text = "cdd6f4ff";
            border = "b4befeff";
          };
        };
      };

      home.file = {
        ".config/hypr" = {
          source = ../../configs/hypr;
          recursive = true;
        };
        ".config/hypr/host_custom.conf" = {
          source = ../../hosts/${hostname}/hyprland.conf;
        };
      };
    };
  };
}
