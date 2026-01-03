# TODO: remove niri-config-specific references
{ config, inputs, lib, nixosConfig, pkgs, ... }:
let
  dankCfg = nixosConfig.ryk.dankMaterialShell;
  rykCfg = nixosConfig.ryk;
in {
  imports = [ inputs.dankMaterialShell.homeModules.dank-material-shell ]
    ++ lib.optionals (rykCfg.niri.enable)
    [ inputs.dankMaterialShell.homeModules.niri ];

  config = let screenshotEditor = dankCfg.screenshotBackend;
  in lib.mkIf rykCfg.dankMaterialShell.enable {

    home.packages = lib.optionals (screenshotEditor == "swappy") [ pkgs.swappy ]
      ++ lib.optionals (screenshotEditor == "satty") [ pkgs.satty ];

    programs.dank-material-shell = {
      enable = true;

      enableAudioWavelength = true;
      enableCalendarEvents = false;
      enableDynamicTheming = false;
      enableSystemMonitoring = true;

      default.settings = {
        currentThemeName = "cat-blue";
        fontFamily = "CaskaydiaCove NFM";
        monoFontFamily = "CaskaydiaMono NFM";

        acMonitorTimeout = 1200;
        acSuspendTime = 1800;
        lockBeforeSuspend = true;

        showWeather = true;
        useFahrenheit = true;
        weatherLocation = "Rosemount, MN";
        weatherCoordinates = "44.747998,-93.133574";
      };
    };

    programs.niri.settings =
      lib.mkIf (rykCfg.niri.enable && rykCfg.niri.bar == "dankMaterialShell") {
        environment = lib.mkIf (screenshotEditor != "none") {
          DMS_SCREENSHOT_EDITOR = screenshotEditor;
        };

        binds = with config.lib.niri.actions;
          let
            spawnAction = actions: spawn ([ "dms" "ipc" "call" ] ++ actions);
            launcherAction = spawnAction [ "spotlight" "toggle" ];
          in {
            "Mod+Print".action = spawn [ "dms" "screenshot" "--no-file" ];
            "Mod+Shift+e".action = spawnAction [ "powermenu" "toggle" ];
            "Mod+Shift+v".action = spawnAction [ "clipboard" "toggle" ];
            "Mod+0".action = spawnAction [ "notepad" "toggle" ];

            "Mod+r".action = launcherAction;
            "Mod+Space".action = launcherAction;
          } // {
            XF86AudioLowerVolume.action =
              spawnAction [ "audio" "decrement" "5" ];
            XF86AudioRaiseVolume.action =
              spawnAction [ "audio" "increment" "5" ];
            XF86AudioMute.action = spawnAction [ "audio" "mute" ];
            XF86Tools.action = spawnAction [ "audio" "micmute" ];
            XF86AudioPlay.action = spawnAction [ "mpris" "playPause" ];
            XF86AudioPause.action = spawnAction [ "mpris" "playPause" ];
            XF86AudioNext.action = spawnAction [ "mpris" "next" ];
            XF86AudioPrev.action = spawnAction [ "mpris" "previous" ];
            XF86MonBrightnessDown.action =
              spawnAction [ "brightness" "decrement" "5" ];
            XF86MonBrightnessUp.action =
              spawnAction [ "brightness" "increment" "5" ];
          };

        spawn-at-startup = [{ argv = [ "dms" "run" ]; }];
      };

    wayland.windowManager.hyprland.settings = lib.mkIf
      (rykCfg.hyprland.enable && rykCfg.hyprland.bar == "dankMaterialShell") {
        bind = let
          dmsIpc = action: "dms ipc call ${action}";
          audioIpc = action: "dms ipc call audio ${action}";
          mprisIpc = action: "dms ipc call mpris ${action}";
          launcher = dmsIpc "spotlight toggle";
        in [
          "$mainMod SHIFT, E, exec, ${dmsIpc "powermenu toggle"}"
          "$mainMod, R, exec, ${launcher}"
          "$mainMod, space, exec, ${launcher}"
          "$mainMod, 0, exec, ${dmsIpc "notepad toggle"}"

          ", XF86AudioMute, exec, ${audioIpc "mute"}"
          ", XF86AudioPlay, exec, ${audioIpc "playPause"}"
          ", XF86AudioPause, exec, ${audioIpc "playPause"}"
          ", XF86AudioNext, exec, ${mprisIpc "next"}"
          ", XF86AudioPrev, exec, ${mprisIpc "previous"}"
          ", XF86MonBrightnessUp, exec, ${dmsIpc "brightness increment 5"}"
          ", XF86MonBrightnessDown, exec, ${dmsIpc "brightness decrement 5"}"
        ];
        exec-once = [ "dms run" ];
      };
  };
}
