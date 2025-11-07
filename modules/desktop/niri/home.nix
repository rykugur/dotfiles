{ config, lib, pkgs, nixosConfig, ... }: {
  config = lib.mkIf nixosConfig.rhx.niri.enable {
    home.packages = with pkgs; [
      albert
      slurp
      swappy
      wayland-utils
      wev
      wl-clipboard
      wl-clipboard-x11
      wlogout
      wtype

      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      gnome-keyring

      xwayland-satellite
    ];

    programs.niri.settings = {
      environment = {
        # DISPLAY = null;

        QT_QPA_PLATFORM = "wayland";

        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "Niri";
        XDG_SESSION_DESKTOP = "Niri";
      };

      input = {
        keyboard = {
          repeat-delay = 200;
          repeat-rate = 60;
          numlock = true;
        };
      };

      outputs = nixosConfig.rhx.niri.monitors;

      spawn-at-startup = [
        { argv = [ "1password" ]; }
        { argv = [ "discord" ]; }
        { argv = [ "steam" ]; }
        { argv = [ "playerctld" "daemon" ]; }
        { argv = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        {
          argv = [ "corectrl" "--minimize-systray" ];
        }
        # { argv = barLaunchCmd; }
        {
          sh =
            "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false";
        }
      ];

      binds = with config.lib.niri.actions;
        {
          "Mod+Return" = {
            action = spawn [ "ghostty" "--gtk-single-instance=true" ];
            repeat = false;
          };

          "Mod+Space".action = lib.mkDefault (spawn [ "albert" "toggle" ]);

          "Mod+Print" = {
            action =
              lib.mkDefault (spawn-sh ''grim -g "$(slurp)" - | wl-copy'');
            repeat = false;
          };

          "Mod+E" = {
            action = lib.mkDefault (spawn [ "nautilus" "--new-window" ]);
            repeat = false;
          };
          "Mod+F" = {
            # action = toggle-windowed-fullscreen;
            action = fullscreen-window;
            repeat = false;
          };
          "Mod+O".action = show-hotkey-overlay;
          # "Mod+Shift+F" = {
          #   action = ;
          #   repeat = false;
          # };
          "Mod+Q" = {
            action = lib.mkDefault close-window;
            repeat = false;
          };
          "Mod+V" = {
            action = toggle-window-floating;
            repeat = false;
          };

          "Mod+Shift+E".action = lib.mkDefault quit;
        } // {
          "Mod+h".action = focus-column-left-or-last;
          "Mod+j".action = focus-window-down-or-top;
          "Mod+k".action = focus-window-up-or-bottom;
          "Mod+l".action = focus-column-right-or-first;

          "Mod+WheelScrollDown".action = focus-window-down-or-top;
          "Mod+WheelScrollUp".action = focus-window-up-or-bottom;

          "Mod+Shift+h".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+j".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+k".action = move-window-up-or-to-workspace-up;
          "Mod+Shift+l".action = move-column-right-or-to-monitor-right;

          # "Mod+Tab".action = focus-window-down-or-column-right;
          # "Mod+Shift+Tab".action = focus-window-up-or-column-left;
        } // {
          XF86AudioLowerVolume.action =
            lib.mkDefault (spawn-sh "amixer sset Master 5%-");
          XF86AudioRaiseVolume.action =
            lib.mkDefault (spawn-sh "amixer sset Master 5%+");
          XF86AudioMute.action =
            lib.mkDefault (spawn-sh "amixer sset Master toggle");
          XF86AudioPlay.action =
            lib.mkDefault (spawn-sh "playerctl play-pause");
          XF86AudioPause.action =
            lib.mkDefault (spawn-sh "playerctl play-pause");
          XF86AudioNext.action = lib.mkDefault (spawn-sh "playerctl next");
          XF86AudioPrev.action = lib.mkDefault (spawn-sh "playerctl previous");
          XF86MonBrightnessUp.action = lib.mkDefault (spawn-sh "xbacklight +5");
          XF86MonBrightnessDown.action =
            lib.mkDefault (spawn-sh "xbacklight -5");
        };

      window-rules = let
        mkFloatingAppRules = appIds:
          lib.map (appId: {
            matches = [{ app-id = appId; }];
            open-floating = true;
          }) appIds;
      in [{
        matches = [{ app-id = "1Password"; }];
        block-out-from = "screen-capture";
      }] ++ (mkFloatingAppRules [
        "com.github.iwalton3.jellyfin-media-player"
        "com.obsproject.Studio"
        "galculator"
        "neovide"
        "nemo"
        "obsidian"
        "opentrack"
        "org.gnome.baobab"
        "org.gnome.Nautilus"
        "org.telegram.desktop"
        "nemo"
        "thunar"
        "org.pulseaudio.pavucontrol"
        "pavucontrol"
        "ristretto"
        "Spotify"
        "virt-manager"
        "vlc"
        "yad"
        "zenity"
        "net.lutris.Lutris"
      ]);
    };
  };
}
