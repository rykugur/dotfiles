{ config, lib, inputs, pkgs, username, hostname, ... }:
let cfg = config.modules.wm.hyprland;
in {
  options.modules.wm.hyprland.enable = lib.mkEnableOption "Enable hyprland.";

  config = lib.mkIf cfg.enable {
    modules.wm = {
      ags.enable = true;
      albert.enable = true;
      swaylock.enable = true;
    };

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    xdg.portal = { enable = true; };

    home-manager.users.${username} = {
      home.packages = [
        inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
        # inputs.mcmojave-hyprcursor.packages.${pkgs.system}.default
      ] ++ (with pkgs; [
        dunst
        libnotify
        grim
        grimblast
        hyprcursor
        hypridle
        hyprlock
        hyprpaper
        slurp
        swappy
        wlogout
      ]);

      wayland.windowManager.hyprland = {
        enable = true;

        extraConfig = ''
          source = ~/.dotfiles/configs/hypr/default.conf
          source = ~/.dotfiles/hosts/${hostname}/hyprland.conf
          source = ~/.dotfiles/configs/hypr/binds.conf
          source = ~/.dotfiles/configs/hypr/input.conf
          source = ~/.dotfiles/configs/hypr/rules.conf
        '';
      };

      home.pointerCursor = {
        name = "phinger-cursors-dark";
        package = pkgs.phinger-cursors;
        size = 32;
        gtk.enable = true;
      };
    };
  };
}
