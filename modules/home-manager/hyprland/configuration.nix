{ config, lib, pkgs, ... }:
let cfg = config.rhx.hyprland;
in {
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      importantPrefixes =
        [ "$" "name" "output" "monitor" "workspace" "bezier" ];

      settings = {
        monitor = config.rhx.hyprland.monitors;

        workspace = config.rhx.hyprland.workspaces;

        misc = {
          disable_hyprland_logo = true;
          vrr = 2;
        };

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";

          layout = lib.mkDefault "hy3";

          allow_tearing = false;
        };

        binds = { workspace_back_and_forth = true; };

        source = [ "${pkgs.catppuccin-ports.hyprland}/themes/mocha.conf" ];

        plugin = {
          hy3 = {
            no_gaps_when_only = 0;
            autotile = {
              enable = true;
              trigger_width = 1220;
              trigger_height = 500;
            };
          };
        };
      };

      plugins = [ pkgs.hyprlandPlugins.hy3 ];
    };
  };
}
