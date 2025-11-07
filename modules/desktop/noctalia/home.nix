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
        binds = with config.lib.niri.actions; {
          "Mod+Shift+E".action =
            spawn [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ];
          "Mod+Shift+V".action =
            spawn [ "noctalia-shell" "ipc" "call" "launcher" "clipboard" ];
          "Mod+R".action =
            spawn [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ];
          "Mod+Space".action =
            spawn [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ];
        };
        spawn-at-startup = [{ argv = [ "noctalia-shell" ]; }];
      };
  };
}
