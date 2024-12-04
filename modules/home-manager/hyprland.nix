{ config, inputs, lib, pkgs, hostname, ... }:
let cfg = config.rhx.hyprland;
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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

    wayland.windowManager.hyprland = let
      perHostConfig = import ../../hosts/${hostname}/hyprland-hm.nix;
      defaultSettings = {
        # set some env variables
        env = [
          "XDG_SESSION_TYPE,wayland"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_DESKTOP,Hyprland"

          "QT_QPA_PLATFORM,wayland"
          "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that

          "COPYCMD,wl-copy"
          "PASTECMD,wl-paste"
        ];
        "$terminal" = "kitty";
        "$fileManager" = "nemo";
        "$menu" = "fuzzel";
        "exec-once" = [
          "1password"
          "albert"
          "ags"
          "discord"
          #"steam"
          "dunst"
          "playerctld daemon"
          "wl-paste --watch cliphist store"
        ];
        general = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          "gaps_in" = 5;
          "gaps_out" = 20;
          "border_size" = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
          # layout = "hy3";
          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false;
        };
        misc = { "disable_hyprland_logo" = true; };
        decoration = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          rounding = 10;

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };

          drop_shadow = "yes";
          shadow_range = 4;
          shadow_render_power = 3;
          col.shadow = "rgba(1a1a1aee)";
        };
        animations = {
          enabled = true;
          first_launch_animation = true;
          bezier = [
            "wind, 0.05, 0.9, 0.1, 1.05"
            "winIn, 0.1, 1.1, 0.1, 1.1"
            "winOut, 0.3, -0.3, 0, 1"
            "liner, 1, 1, 1, 1"
          ];
          animation = [
            "windows, 1, 6, wind, slide"
            "windowsIn, 1, 6, winIn, slide"
            "windowsOut, 1, 5, winOut, slide"
            "windowsMove, 1, 5, wind, slide"
            "border, 1, 1, liner"
            "borderangle, 1, 30, liner, loop"
            "fade, 1, 10, default"
            "workspaces, 1, 5, wind"
          ];

        };
        dwindle = {
          pseudotile =
            "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = "yes"; # you probably want this
          force_split = 2;

        };
        master = {
          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          new_is_master = false;
        };
        windowrulev2 = [
          "float, class:(1Password)"
          "float, class:(com.github.iwalton3.jellyfin-media-player)"
          "float, class:(com.obsproject.Studio)"
          "float, class:(galculator)"
          "float, class:(neovide)"
          "float, class:(nemo)"
          "float, class:(thunar)"
          "float, class:(pavucontrol)"
          "float, class:(ristretto) # image viewer"
          "float, class:(Spotify)"
          "float, class:(virt-manager)"
          "float, class:(vlc)"
          "float, class:(yad)"
          "float, class:(zenity)"
        ];
      };
    in {
      enable = true;

      settings = perHostConfig.preSettings // { } // perHostConfig.postSettings;

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
}
