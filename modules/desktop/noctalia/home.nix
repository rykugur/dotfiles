{ config, inputs, lib, nixosConfig, ... }:
let rhxCfg = nixosConfig.rhx;
in {
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf rhxCfg.noctalia.enable {
    programs.noctalia-shell = {
      enable = true;

      # TODO: customize these; they were copied from the docs
      settings = {
        # configure noctalia here; defaults will
        # be deep merged with these attributes.
        bar = {
          density = "compact";
          position = "right";
          showCapsule = false;
          widgets = {
            left = [
              {
                id = "SidePanelToggle";
                useDistroLogo = true;
              }
              { id = "WiFi"; }
              { id = "Bluetooth"; }
            ];
            center = [{
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }];
            right = [
              {
                alwaysShowPercentage = false;
                id = "Battery";
                warningThreshold = 30;
              }
              {
                formatHorizontal = "HH:mm";
                formatVertical = "HH mm";
                id = "Clock";
                useMonospacedFont = true;
                usePrimaryColor = true;
              }
            ];
          };
        };
        colorSchemes.predefinedScheme = "Monochrome";
        general = {
          avatarImage = "/home/drfoobar/.face";
          radiusRatio = 0.2;
        };
        location = {
          monthBeforeDay = true;
          name = "Marseille, France";
        };
      };
    };

    programs.niri.settings =
      lib.mkIf (rhxCfg.niri.enable && rhxCfg.niri.bar == "noctalia") {
        binds = with config.lib.niri.actions;
          let
            spawnAction = actions:
              spawn ([ "noctalia-shell" "ipc" "call" ] ++ actions);
            launcherAction = spawnAction [ "launcher" "toggle" ];
          in {
            "Mod+Shift+e".action = spawnAction [ "sessionMenu" "toggle" ];
            "Mod+Shift+v".action = spawnAction [ "launcher" "clipboard" ];
            "Mod+r".action = launcherAction;
            "Mod+Space".action = launcherAction;
          } // {
            XF86AudioLowerVolume.action =
              spawnAction [ "volume" "decrease" "5" ];
            XF86AudioRaiseVolume.action =
              spawnAction [ "volume" "increase" "5" ];
            XF86AudioMute.action = spawnAction [ "volume" "muteOutput" ];
            XF86AudioPlay.action = spawnAction [ "media" "playPause" ];
            XF86AudioPause.action = spawnAction [ "media" "playPause" ];
            XF86AudioNext.action = spawnAction [ "media" "next" ];
            XF86AudioPrev.action = spawnAction [ "media" "previous" ];
            XF86MonBrightnessDown.action =
              spawnAction [ "brightness" "decrease" "5" ];
            XF86MonBrightnessUp.action =
              spawnAction [ "brightness" "increase" "5" ];
          };
        spawn-at-startup = [{ argv = [ "noctalia-shell" ]; }];
      };
  };
}
