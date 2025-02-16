{ config, inputs, lib, pkgs, hostname, ... }:
let
  cfg = config.rhx.hyprland;
  catppuccin-hyprland = pkgs.fetchgit {
    url = "https://github.com/catppuccin/hyprland";
    rev = "v1.3";
    sha256 = "sha256-jkk021LLjCLpWOaInzO4Klg6UOR4Sh5IcKdUxIn7Dis=";
  };
  catppuccin-hyprlock = pkgs.fetchgit {
    url = "https://github.com/catppuccin/hyprlock";
    rev = "958e70b1cd8799defd16dee070d07f977d4fd76b";
    sha256 = "sha256-l4CbAUeb/Tg603QnZ/VWxuGqRBztpHN0HLX/h8ndc5w=";
  };
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    rhx.albert.enable = true;
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
        source = ~/.dotfiles/configs/hypr/binds.conf
        source = ~/.dotfiles/configs/hypr/input.conf
        source = ~/.dotfiles/configs/hypr/rules.conf

        source = ${catppuccin-hyprland}/themes/mocha.conf
      '';
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        source = [
          "${catppuccin-hyprlock}/hyprlock.conf"
          "${catppuccin-hyprland}/themes/mocha.conf"
        ];
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
