{ config, fetchgit, inputs, lib, pkgs, hostname, ... }:
let
  cfg = config.rhx.hyprland;
  catppuccin-hyprland = fetchgit {
    url = "https://github.com/catppuccin/hyprland";
    rev = "main";
    sha256 = lib.fakeSha256;
  };
  catppuccin-hyprlock = fetchgit {
    url = "https://github.com/catppuccin/hyprlock";
    rev = "main";
    sha256 = lib.fakeSha256;
  };
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    rhx.ranger.enable = true;
    rhx.thunar.enable = true;

    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
      inputs.hyprland-qtutils.packages."${pkgs.system}".default
      # inputs.mcmojave-hyprcursor.packages.${pkgs.system}.default
    ] ++ (with pkgs; [
      libnotify
      grim
      grimblast
      hyprcursor
      hypridle
      hyprpanel
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

    programs.hyprlock = {
      enable = true;
      settings = { source = [ "${catppuccin-hyprland}/themes/mocha.conf" ]; };
    };

    home.file = {
      ".config/hypr/hyprlock.conf" = {
        source = "${catppuccin-hyprlock}/hyprlock.conf";
      };
    };

    home.pointerCursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 32;
      gtk.enable = true;
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;

        preload = [ "~/.wallpapers/StarCitizen_40_4k_Wallpaper_01.jpg" ];

        wallpaper = [ ",~/.wallpapers/StarCitizen_40_4k_Wallpaper_01.jpg" ];
      };
    };
  };
}
