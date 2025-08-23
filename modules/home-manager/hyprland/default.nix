{ config, lib, pkgs, ... }:
let cfg = config.rhx.hyprland;
in {
  imports = [
    ./autostart.nix
    ./binds.nix
    ./configuration.nix
    ./input.nix
    ./looknfeel.nix
    ./vars.nix

    ./hypridle.nix
    ./hyprpanel.nix
    ./waybar.nix
  ];

  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";

    theme = lib.mkOption {
      type = lib.types.enum [
        "catppuccin-mocha"
        "catppuccin-latte"
        "catppuccin-macchiato"
        "catppuccin-frappe"
      ];
      default = "catppuccin-mocha";
      description =
        "Catppuccin theme for hyprland and its submodules. Available themes are catppuccin-mocha, catppuccin-latte, catppuccin-macchiato, and catppuccin-frappe.";
    };

    hyprpanel.enable =
      lib.mkEnableOption "Enable hyprpanel for hyprland home-manager module.";

    waybar.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.rhx.hyprland.enable;
      description = "Enable waybar for hyprland home-manager module.";
    };
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
