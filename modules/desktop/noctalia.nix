{ inputs, self, ... }:
{
  flake.modules.nixos.noctalia =
    { config, lib, ... }:
    let
      cfg = config.ryk.noctalia;
    in
    {
      options.ryk.noctalia.enable = lib.mkEnableOption "the noctalia quickshell bar";

      config = lib.mkIf cfg.enable {
        home-manager.users.${config.ryk.username}.imports = [ self.modules.homeManager.noctalia ];
      };
    };

  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      nixosConfig,
      ...
    }:
    let
      # Only the active compositor's integration is declared; the other
      # compositor's home-manager options may not even exist on this host.
      isNiri = nixosConfig.ryk.desktop.compositor == "niri";
      noctalia = args: [ "noctalia" "msg" ] ++ args;
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];

      config = lib.mkMerge [
        {
          # Noctalia v5 uses TOML under programs.noctalia. This is the v5
          # equivalent of the former programs.noctalia-shell JSON config.
          programs.noctalia = {
            enable = true;
            systemd.enable = true;
            settings = {
              shell = {
                avatar_path = "${config.home.homeDirectory}/.face";
                corner_radius_scale = 0.2;
                show_location = true;
              };

              # v4's predefined "Monochrome" palette is now a wallpaper color
              # source using the m3-monochrome scheme.
              theme = {
                mode = "dark";
                source = "wallpaper";
                wallpaper_scheme = "m3-monochrome";
              };

              location = {
                auto_locate = false;
                address = "Marseille, France";
              };

              bar.main = {
                position = "right";
                thickness = 34;
                padding = 8;
                widget_spacing = 4;
                radius = 7;
                capsule = false;

                # v4 SidePanelToggle maps to the v5 control-center panel.
                start = [
                  "control-center"
                  "network"
                  "bluetooth"
                ];
                center = [ "workspaces" ];
                end = [
                  "battery"
                  "clock"
                ];
              };

              widget = {
                workspaces = {
                  hide_when_empty = false;
                  show_labels = false;
                };
                battery.show_label = false;
                clock = {
                  format = "{:%H:%M}";
                  vertical_format = "{:%H\n%M}";
                };
              };
            };
          };
        }

        (lib.optionalAttrs isNiri {
          programs.niri.settings.binds =
            with config.lib.niri.actions;
            {
              "Mod+Shift+e".action = spawn (noctalia [
                "panel-toggle"
                "session"
              ]);
              "Mod+Shift+v".action = spawn (noctalia [
                "panel-toggle"
                "clipboard"
              ]);
              "Mod+Space".action = spawn (noctalia [
                "panel-toggle"
                "launcher"
              ]);
            }
            // {
              XF86AudioLowerVolume.action = spawn (noctalia [
                "volume-down"
                "5"
              ]);
              XF86AudioRaiseVolume.action = spawn (noctalia [
                "volume-up"
                "5"
              ]);
              XF86AudioMute.action = spawn (noctalia [ "volume-mute" ]);
              XF86AudioPlay.action = spawn (noctalia [
                "media"
                "toggle"
              ]);
              XF86AudioPause.action = spawn (noctalia [
                "media"
                "toggle"
              ]);
              XF86AudioNext.action = spawn (noctalia [
                "media"
                "next"
              ]);
              XF86AudioPrev.action = spawn (noctalia [
                "media"
                "previous"
              ]);
              XF86MonBrightnessDown.action = spawn (noctalia [
                "brightness-down"
                "current"
                "5"
              ]);
              XF86MonBrightnessUp.action = spawn (noctalia [
                "brightness-up"
                "current"
                "5"
              ]);
            };
        })
      ];
    };
}
