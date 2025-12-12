{ config, lib, pkgs, nixosConfig, ... }:
let niriCfg = nixosConfig.rhx.niri;
in {
  config = lib.mkIf niriCfg.enable {
    home.packages = with pkgs;
      [
        albert
        slurp
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
      ] ++ [
        (pkgs.writeScriptBin "conditional-kill.nu"
          (builtins.readFile ./scripts/conditional-kill.nu))
        (pkgs.writeScriptBin "eve-toggle.nu"
          (builtins.readFile ./scripts/toggle-eve.nu))
      ];

    programs.niri.settings = let
      p25 = { proportion = 1.0 / 4.0; };
      p33 = { proportion = 1.0 / 3.0; };
      p50 = { proportion = 1.0 / 2.0; };
      p66 = { proportion = 2.0 / 3.0; };
      p75 = { proportion = 3.0 / 4.0; };
      p100 = { proportion = 1.0; };
    in {
      # debug = { skip-cursor-only-updates-during-vrr = [ ]; };

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
          xkb = {
            layout = "us";
            options = "fkeys:basic_13-24";
          };
        };
        # TODO: waiting for flake owner to implement this
        # touch = let
        #   matrices = {
        #     "0" = [ 1.0 0.0 0.0 0.0 1.0 0.0 ];
        #     "90" = [ 0.0 1.0 0.0 (-1.0) 0.0 1.0 ];
        #     "180" = [ (-1.0) 0.0 1.0 0.0 (-1.0) 1.0 ];
        #     "270" = [ 0.0 (-1.0) 1.0 1.0 0.0 0.0 ];
        #   };
        # in lib.mkIf (niriCfg.touch.input != null) {
        #   enable = true;
        #   map-to-output = niriCfg.touch.input;
        #   calibration-matrix = lib.mkIf (niriCfg.touch.rotation != null)
        #     matrices.${niriCfg.touch.rotation};
        # };
      };

      outputs = niriCfg.monitors;

      layout = {
        # TODO: update these to use niriCfg.defaultColumnWidth and
        # niriCfg.proportions
        preset-column-widths = [ p25 p33 p50 p66 p75 p100 ];
        default-column-width = p66;
      };

      spawn-at-startup = [
        { argv = [ "1password" ]; }
        { argv = [ "discord" ]; }
        { argv = [ "steam" ]; }
        { argv = [ "playerctld" "daemon" ]; }
        { argv = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        { argv = [ "corectrl" "--minimize-systray" ]; }
        {
          sh =
            "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false";
        }
      ];

      binds = with config.lib.niri.actions;
        let launcherAction = spawn [ "albert" "toggle" ];
        in {
          "Mod+Return" = {
            action = spawn [ "ghostty" "--gtk-single-instance=true" ];
            repeat = false;
          };
          "Mod+r".action = lib.mkDefault launcherAction;
          "Mod+Space".action = lib.mkDefault launcherAction;
          "Mod+Print" = {
            action =
              lib.mkDefault (spawn-sh ''grim -g "$(slurp)" - | wl-copy'');
            repeat = false;
          };
          "Mod+e" = {
            action = lib.mkDefault (spawn [ "nautilus" "--new-window" ]);
            repeat = false;
          };
          "Mod+f" = {
            action = fullscreen-window;
            repeat = false;
          };
          "Mod+g" = {
            action = lib.mkDefault (spawn [
              "${config.home.homeDirectory}/.nix-profile/bin/eve-toggle.nu"
            ]);
            repeat = false;
          };
          "Mod+o".action = show-hotkey-overlay;
          "Mod+q" = {
            action = lib.mkDefault (spawn [
              "${config.home.homeDirectory}/.nix-profile/bin/conditional-kill.nu"
            ]);
            repeat = false;
          };
          "Mod+v" = {
            action = toggle-window-floating;
            repeat = false;
          };
          "Mod+w" = {
            action = toggle-column-tabbed-display;
            repeat = false;
          };

          "Mod+Shift+e".action = lib.mkDefault quit;

          "Mod+p".action = lib.mkDefault switch-preset-column-width;
          "Mod+Shift+p".action = lib.mkDefault switch-preset-column-width-back;

          # TODO: `niri msg pick-window`
        } // {
          "Mod+h".action = focus-column-left-or-last;
          "Mod+j".action = focus-window-or-workspace-down;
          "Mod+k".action = focus-window-or-workspace-up;
          "Mod+l".action = focus-column-right-or-first;

          "Mod+WheelScrollUp".action = focus-column-left;
          "Mod+WheelScrollDown".action = focus-column-right;

          "Mod+Shift+h".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+j".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+k".action = move-window-up-or-to-workspace-up;
          "Mod+Shift+l".action = move-column-right-or-to-monitor-right;

          "Mod+Tab" = {
            action = toggle-overview;
            cooldown-ms = 250;
          };
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
          XF86Tools.action =
            lib.mkDefault (spawn-sh "amixer sset Capture toggle");
        };

      window-rules = let
        mkFloatingAppRule = appInfo: {
          matches = [{
            app-id = appInfo.appId or null;
            title = appInfo.title or null;
          }];
          open-floating = true;
        };
        mkFloatingAppRules = appInfos:
          lib.map (appInfo: mkFloatingAppRule appInfo) appInfos;
      in [
        ((mkFloatingAppRule { appId = "1password"; }) // {
          block-out-from = "screen-capture";
        })
        {
          geometry-corner-radius = let r = 8.0;
          in {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }
        {
          matches = [{ app-id = "com.mitchellh.ghostty"; }];
          default-column-width = p33;
        }
        {
          matches = [{ app-id = "discord"; }];
          default-column-width = p50;

        }
      ] ++
      # game-specific rules
      [
        {
          matches = [{
            app-id = "steam";
            title = "Friends List";
          }];
          default-column-width = p33;
        }
        # {
        #   matches = [{
        #     app-id = "gamescope";
        #     title = "ARC Raiders";
        #   }];
        #   variable-refresh-rate = true;
        # }
        {
          matches = [{
            appId = "steam_app_8500";
            title = "EVE Launcher";
          }];
          default-column-width = p33;
          # variable-refresh-rate = true;
        }
        # {
        #   matches = [{
        #     app-id = "starcitizen.exe";
        #     # title = "^Star Citizen.*$";
        #   }];
        #   variable-refresh-rate = true;
        # }
      ] ++ (mkFloatingAppRules [
        { appId = "galculator"; }
        { appId = "neovide"; }
        { appId = "nemo"; }
        { appId = "obsidian"; }
        { appId = "opentrack"; }
        { appId = "org.gnome.Nautilus"; }
        { appId = "nemo"; }
        { appId = "thunar"; }
        { appId = "org.pulseaudio.pavucontrol"; }
        { appId = "pavucontrol"; }
        { appId = "ristretto"; }
        { appId = "vlc"; }
        { appId = "yad"; }
        { appId = "zenity"; }
      ]);
    };
  };
}
