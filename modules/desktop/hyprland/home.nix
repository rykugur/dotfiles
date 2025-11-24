{ lib, pkgs, nixosConfig, ... }:
let hyprCfg = nixosConfig.rhx.hyprland;
in {
  config = lib.mkIf nixosConfig.rhx.hyprland.enable {

    rhx = { nautilus.enable = true; };

    home.packages = with pkgs; [
      hyprprop
      hyprland-qtutils
      libnotify
      grim
      grimblast
      hyprcursor
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

    # home.pointerCursor = {
    #   name = "phinger-cursors-dark";
    #   package = pkgs.phinger-cursors;
    #   size = 32;
    #   gtk.enable = true;
    # };

    services = {
      hypridle = lib.mkIf hyprCfg.hypridle.enable {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 330;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

      hyprpolkitagent.enable = true;
    };

    programs = {
      hyprlock = lib.mkIf hyprCfg.hyprlock.enable { enable = true; };
    };

    wayland.windowManager.hyprland = {
      enable = true;

      importantPrefixes =
        [ "$" "name" "output" "monitor" "workspace" "bezier" ];

      plugins = lib.optionals hyprCfg.hy3.enable [ pkgs.hyprlandPlugins.hy3 ];

      settings = {
        monitor = hyprCfg.monitors;

        workspace = hyprCfg.workspaces;

        misc = {
          disable_hyprland_logo = true;
          vrr = 2;
        };

        env = [
          "XDG_SESSION_TYPE,wayland"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_QPA_PLATFORM,wayland"
          "QT_QPA_PLATFORMTHEME,qt5ct # change to qt6ct if you have that"
          "COPYCMD,wl-copy"
          "PASTECMD,wl-paste"
        ];

        "$mainMod" = lib.mkDefault "SUPER";
        "$terminal" = lib.mkDefault "ghostty --gtk-single-instance=true";
        "$browser" = lib.mkDefault "zen";
        "$fileManager" = lib.mkDefault "nautilus --new-window";
        "$music" = lib.mkDefault "spotify";
        "$passwordManager" = lib.mkDefault "1password";
        "$messenger" = lib.mkDefault "signal-desktop";
        "$webapp" = lib.mkDefault "$browser --app";

        "$discordWorkspace" = lib.mkDefault 3;
        "$steamWorkspace" = lib.mkDefault 3;
        "$gamingWorkspace" = lib.mkDefault 4;

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          # "col.inactive_border" = "rgba(595959aa)";

          layout = lib.mkDefault "hy3";

          allow_tearing = false;
        };

        plugin = lib.optionalAttrs hyprCfg.hy3.enable {
          hy3 = {
            no_gaps_when_only = 0;
            autotile = {
              enable = true;
              trigger_width = 1220;
              trigger_height = 500;
            };
          };
        };

        exec-once = [
          "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
          "1password"
          "albert"
          "discord"
          "steam"
          "playerctld daemon"
          "wl-paste --watch cliphist store"
          "corectrl --minimize-systray"
        ]
        # TODO: move this to caelestia module
          ++ lib.optionals (hyprCfg.bar == "caelestia") [ "caelestia-shell" ];

        animations = {
          enabled = true;
          # first_launch_animation = true;

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
            # "workspaces, 1, 5, wind"
            "workspacesIn, 1, 5, wind, slidevert 100%"
            "workspacesOut, 1, 5, wind, slidevert -100%"
          ];
        };

        decoration = {
          rounding = 10;

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };

          shadow = {
            range = 4;
            render_power = 3;
            # color = "rgba(1a1a1aee)";
          };
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";

          numlock_by_default = true;

          follow_mouse = 2;
          # fixes oddities with drop-down menu items, e.g. steam
          mouse_refocus = false;

          touchpad = {
            natural_scroll = "no";
            tap-to-click = true;
            clickfinger_behavior = true;
          };

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

          repeat_rate = 60;
          repeat_delay = 200;
        };

        binds = { workspace_back_and_forth = true; };

        bind = let
          moveFocusCommand =
            if hyprCfg.hy3.enable then "hy3:movefocus" else "movefocus";
          moveWindowCommand =
            if hyprCfg.hy3.enable then "hy3:movewindow" else "movewindow";
        in [
          "$mainMod, Return, exec, $terminal"
          "$mainMod SHIFT, Return, exec, [float] $terminal"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, Q, exec, ~/.dotfiles/configs/hypr/scripts/conditional-killactive.nu"
          "$mainMod SHIFT, Q, killactive,"

          "$mainMod, F, fullscreen"
          "$mainMod, V, togglefloating"

          "$mainMod SHIFT, F1, exec, ~/.dotfiles/configs/hypr/scripts/hyprprop-wlcopy.nu"
          "$mainMod, g, exec, ~/.dotfiles/configs/nu/scripts/toggle-eve.nu"
        ] ++ [
          "$mainMod, h, ${moveFocusCommand}, l"
          "$mainMod, j, ${moveFocusCommand}, d"
          "$mainMod, k, ${moveFocusCommand}, u"
          "$mainMod, l, ${moveFocusCommand}, r"

          "$mainMod SHIFT, h, ${moveWindowCommand}, l"
          "$mainMod SHIFT, j, ${moveWindowCommand}, d"
          "$mainMod SHIFT, k, ${moveWindowCommand}, u"
          "$mainMod SHIFT, l, ${moveWindowCommand}, r "

          "$mainMod, 0, togglespecialworkspace, special"
          "$mainMod SHIFT, 0, movetoworkspace, special"
          "$mainMod, mouse_down, workspace, e-1"
          "$mainMod, mouse_up, workspace, e+1"
        ] ++ [ ] ++ lib.optionals (hyprCfg.bar == "none") [
          "$mainMod SHIFT, E, exec, wlogout"
          "$mainMod, R, exec, albert toggle"
          "$mainMod, space, exec, albert toggle"
          ''$mainMod, Pritn, exec, grim -g "$(slurp)" - | wl-copy''

          ", XF86AudioMute, exec, amixer sset Master toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86MonBrightnessUp, exec, exec, xbacklight +5"
          ", XF86MonBrightnessDown, exec, exec, xbacklight -5"
        ];

        binde = lib.optionals (hyprCfg.bar == "none") [
          ", XF86AudioRaiseVolume, exec, amixer sset Master 5%+"
          ", XF86AudioLowerVolume, exec, amixer sset Master 5%-"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        windowrulev2 = [
          "float, class:(1Password)"
          "float, class:(com.github.iwalton3.jellyfin-media-player)"
          "float, class:(Jellyfin)"
          "float, class:^chrome.*, title:(Jellyfin)"
          "float, class:(com.obsproject.Studio)"
          "float, title:(Select what to share)" # OBS screen/window selector popup
          "float, class:(galculator)"
          "float, class:(neovide)"
          "float, class:(nemo)"
          "float, class:(obsidian)"
          "float, class:(opentrack)"
          "float, class:(org.gnome.baobab)"
          "float, class:(org.gnome.Nautilus)"
          "float, class:(org.pulseaudio.pavucontrol)"
          "float, class:(org.telegram.desktop)"
          "float, class:(nemo)"
          "float, class:(thunar)"
          "float, class:(pavucontrol)"
          "float, class:(ristretto)"
          "float, class:(Spotify)"
          "float, class:(virt-manager)"
          "float, class:(vlc)"
          "float, class:(yad)"
          "float, class:(zenity)"
          "float, class:zen-beta,title:Picture-in-Picture"
          "float, class:(net.lutris.Lutris)"
          "size 1920 1080, class:(net.lutris.Lutris)"
          "float, class:^org.telegram.desktop$, title:^Media viewer$"
          "float, class:net.davidotek.pupgui2"
          "workspace 4 silent, class:(discord)"
          "workspace 4 silent, class:^(steam)$"
          "workspace 4 silent, title:(Friends List)"
          "float, class:(steam), title:(Friends List)"
          "stayfocused, title:^()$,class:^(steam)$"
          "minsize 1 1, title:^()$,class:^(steam)$"
          "workspace $gamingWorkspace silent, class:(dota2)"
          "workspace $gamingWorkspace silent, class:^(RimWorldLinux)$"
          "workspace $steamWorkspace silent, class:^(steam_app_8500)$,title:^(EVE Launcher)$,initialClass:^(steam_app_8500)$,initialTitle:^(EVE Launcher)$"
          "fullscreenstate:2 -1, initialTitle:^(EVE)$"
          "workspace $gamingWorkspace silent, class:(Project Zomboid)"
          "fullscreen, class:(Project Zomboid)"
          "workspace $gamingWorkspace silent, class:(X4)"
        ];
      };
    };
  };
}
