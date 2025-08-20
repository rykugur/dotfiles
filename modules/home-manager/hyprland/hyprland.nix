{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.hyprland;
  catppuccin-hyprland = pkgs.fetchgit {
    url = "https://github.com/catppuccin/hyprland";
    rev = "v1.3";
    sha256 = "sha256-jkk021LLjCLpWOaInzO4Klg6UOR4Sh5IcKdUxIn7Dis=";
  };
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    imports = [ (import ./hyprlock.nix { inherit catppuccin-hyprland; }) ];
    rhx.hyprpanel.enable = true;
    rhx.thunar.enable = true;

    # launchers
    rhx.albert.enable = true;
    rhx.vicinae.enable = true;
    rhx.walker.enable = true;

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
        source = ~/.dotfiles/configs/hypr/plugins.conf

        source = ${catppuccin-hyprland}/themes/mocha.conf
      '';

      plugins = [ pkgs.hyprlandPlugins.hy3 ];
    };

    home.pointerCursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 32;
      gtk.enable = true;
    };

    services = {
      hyprpaper = {
        enable = true;
        settings = {
          ipc = "on";
          splash = false;
          splash_offset = 2.0;

          preload = [ "~/.wallpapers/cyberpunk_skull.png" ];

          wallpaper = [ ",~/.wallpapers/cyberpunk_skull.png" ];
        };
      };

      hyprpolkitagent.enable = true;
    };

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = { "inode/directory" = [ "nemo.desktop" ]; };
      };
    };
  };
}
