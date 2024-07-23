{ config, lib, inputs, pkgs, username, hostname, ... }:
let
  cfg = config.modules.wm.hyprland;
  walkerOverride = pkgs.walker.overrideAttrs (old: { version = "0.1.1"; });
in {
  options.modules.wm.hyprland.enable = lib.mkEnableOption "Enable hyprland.";

  config = lib.mkIf cfg.enable {
    modules.wm = {
      ags.enable = true;
      albert.enable = true;
    };

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
      home.packages = with pkgs;
        [
          dunst
          libnotify
          grim
          grimblast
          hypridle
          hyprlock
          hyprpaper
          inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
          slurp
          swappy
          wlogout
        ] ++ [ walkerOverride ];

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

      wayland.windowManager.hyprland = {
        enable = true;

        extraConfig = ''
          source = ~/.dotfiles/hosts/${hostname}/hyprland.conf
          source = ~/.dotfiles/configs/hypr/default.conf
          source = ~/.dotfiles/configs/hypr/binds.conf
          source = ~/.dotfiles/configs/hypr/input.conf
          source = ~/.dotfiles/configs/hypr/rules.conf
        '';

        plugins = with pkgs.hyprlandPlugins; [ hyprspace ];

        # settings = { monitor = "DP-1,3440x1440@144,0x0,1"; };
        # extraConfig = ''
        #   ${builtins.readFile ../../hosts/${hostname}/hyprland.conf}";
        #   ${builtins.readFile ../../configs/hypr/binds.conf}";
        #   ${builtins.readFile ../../configs/hypr/default.conf}";
        #   ${builtins.readFile ../../configs/hypr/input.conf}";
        #   ${builtins.readFile ../../configs/hypr/rules.conf}";
        # '';

        # "source" = "~/.config/hypr/hyprland.conf";
        # "source" = "~/.config/hypr/binds.conf";
        # "source" = "~/.config/hypr/input.conf";
        # "source" = "~/.config/hypr/rules.conf";

        # source = ~/.config/hypr/default.conf
        # source = ~/.config/hypr/binds.conf
        # source = ~/.config/hypr/input.conf
        # source = ~/.config/hypr/rules.conf
        # source = ~/.config/hypr/host_custom.conf
      };

      # home.file = {
      #   ".config/hypr" = {
      #     source = config.lib.file.mkOutOfStoreSymlink
      #       "${config.home.homeDirectory}/.dotfiles/configs/hypr";
      #     recursive = true;
      #   };
      # ".config/hypr/host_custom.conf" = {
      #   source = config.lib.file.mkOutOfStoreSymlink
      #     "${config.home.homeDirectory}/.dotfiles/hosts/${hostname}/hyprland.conf";
      # };
      # };
    };
  };
}
