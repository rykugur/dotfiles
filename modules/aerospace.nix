{ ... }:
{
  # TODO: this cannot be called from nixOS, darwin only
  flake.nixosModules.aerospace =
    { ... }:
    {
      system = {
        defaults = {
          dock = {
            expose-group-apps = true;
          };
          spaces = {
            spans-displays = true;
          };
        };
      };
    };

  flake.homeModules.aerospace =
    { ... }:
    {
      programs.aerospace = {
        enable = true;
        userSettings = {
          mode = {
            main = {
              binding = {
                alt-1 = "workspace 1";
                alt-2 = "workspace 2";
                alt-3 = "workspace 3";
                alt-4 = "workspace 4";
                alt-5 = "workspace 5";
                alt-6 = "workspace 6";
                alt-7 = "workspace 7";

                alt-shift-1 = "move-node-to-workspace 1";
                alt-shift-2 = "move-node-to-workspace 2";
                alt-shift-3 = "move-node-to-workspace 3";
                alt-shift-4 = "move-node-to-workspace 4";
                alt-shift-5 = "move-node-to-workspace 5";
                alt-shift-6 = "move-node-to-workspace 6";
                alt-shift-7 = "move-node-to-workspace 7";

                alt-tab = "workspace-back-and-forth";

                alt-h = "focus left";
                alt-j = "focus down";
                alt-k = "focus up";
                alt-l = "focus right";

                alt-shift-h = "move left";
                alt-shift-j = "move down";
                alt-shift-k = "move up";
                alt-shift-l = "move right";

                alt-f = "fullscreen";

                alt-s = "layout v_accordion";
                alt-w = "layout h_accordion";
                alt-e = "layout tiles horizontal vertical";

                alt-shift-space = "layout floating tiling";

                alt-r = "mode resize";

                alt-minus = "resize smart -50";
                alt-equal = "resize smart +50";

                alt-slash = "layout tiles horizontal vertical";
                alt-comma = "layout accordion horizontal vertical";
              };
            };
            resize = {
              binding = {
                h = "resize width -50";
                j = "resize height -50";
                k = "resize height +50";
                l = "resize width +50";
                enter = "mode main";
                esc = "mode main";
              };
            };
          };
        };
      };
    };
}
