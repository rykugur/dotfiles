{ config, lib, pkgs, ... }:
let cfg = config.rhx.hyprland;
in {
  imports = [
    ./autostart.nix
    ./binds.nix
    ./configuration.nix
    ./input.nix
    ./looknfeel.nix
    ./rules.nix
    ./vars.nix

    ./hypridle.nix
    ./hyprlock.nix

    # bars
    ./quickshell.nix
    ./hyprpanel.nix
    ./waybar.nix
  ];

  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Monitors to define.";
    };

    workspaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1" "2" "3" ];
      description = "Workspaces to define.";
    };

    hy3.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hy3 plugin for i3 like tiling.";
    };

    quickshell.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.rhx.hyprland.enable;
      description = "Enable quickshell for hyprland home-manager module.";
    };

    hypridle.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.rhx.hyprland.enable;
      description = "Enable hypridle";
    };

    hyprlock.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.rhx.hyprland.enable;
      description = "Enable hyprlock";
    };

    hyprpanel.enable =
      lib.mkEnableOption "Enable hyprpanel for hyprland home-manager module.";

    waybar.enable =
      lib.mkEnableOption "Enable waybar for hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    rhx = {
      nemo.enable = true;

      # launchers
      albert.enable = true;
      vicinae.enable = true;
      walker.enable = true;
    };

    home.packages = with pkgs; [
      hyprprop
      hyprland-qtutils
      libnotify
      grim
      grimblast
      hyprcursor
      hypridle
      pywal
      slurp
      swappy
      wev
      wl-clipboard
      wl-clipboard-x11
      wlogout
      # wofi
      # wofi-emoji
      wtype
    ];

    home.pointerCursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 32;
      gtk.enable = true;
    };

    services.hyprpolkitagent.enable = true;
  };
}
