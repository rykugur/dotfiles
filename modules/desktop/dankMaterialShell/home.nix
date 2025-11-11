{ config, inputs, lib, nixosConfig, pkgs, ... }:
let rhxCfg = nixosConfig.rhx;
in {
  imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ]
    ++ lib.optionals (rhxCfg.niri.enable)
    [ inputs.dankMaterialShell.homeModules.dankMaterialShell.niri ];

  config = let screenshotEditor = rhxCfg.niri.screenshotBackend;
  in lib.mkIf rhxCfg.dankMaterialShell.enable {

    home.packages = lib.optionals (screenshotEditor != "none")
      (if screenshotEditor == "swappy" then
        [ pkgs.swappy ]
      else if screenshotEditor == "satty" then
        [ pkgs.satty ]
      else
        [ ]);

    programs.dankMaterialShell = {
      enable = true;

      enableAudioWavelength = true;
      enableBrightnessControl = false;
      enableCalendarEvents = false;
      enableClipboard = true;
      enableDynamicTheming = false;
      enableSystemMonitoring = true;
      enableSystemSound = false;

      default.settings = {
        useFahrenheit = true;
        weatherLocation = "Rosemount, MN";
        weatherCoordinates = "44.747998,-93.133574";
      };
    };

    programs.niri.settings =
      lib.mkIf (rhxCfg.niri.enable && rhxCfg.niri.bar == "dankMaterialShell") {
        environment = lib.mkIf (screenshotEditor != "none") {
          DMS_SCREENSHOT_EDITOR = screenshotEditor;
        };

        binds = with config.lib.niri.actions;
          let spawnAction = actions: spawn ([ "dms" "ipc" "call" ] ++ actions);
          in { } // {
            "Mod+Print".action = spawnAction [ "niri" "screenshot" ];
            "Mod+Shift+e".action = spawnAction [ "powermenu" "toggle" ];
            "Mod+Shift+v".action = spawnAction [ "clipboard" "toggle" ];
            "Mod+Space".action = spawnAction [ "spotlight" "toggle" ];
            "Mod+0".action = spawnAction [ "notepad" "toggle" ];
          } // {
            XF86AudioLowerVolume.action =
              spawnAction [ "audio" "decrement" "5" ];
            XF86AudioRaiseVolume.action =
              spawnAction [ "audio" "increment" "5" ];
            XF86AudioMute.action = spawnAction [ "audio" "mute" ];
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
  };
}
