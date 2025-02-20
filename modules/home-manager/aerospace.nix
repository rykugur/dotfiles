{ config, lib, ... }:
let cfg = config.rhx.aerospace;
in {
  options.rhx.aerospace = {
    enable = lib.mkEnableOption "Enable aerospace home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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

              alt-h = "focus left";
              alt-j = "focus down";
              alt-k = "focus up";
              alt-l = "focus right";

              alt-shift-h = "move left";
              alt-shift-j = "move down";
              alt-shift-k = "move up";
              alt-shift-l = "move right";

              alt-r = "mode resize";
            };
          };
          resize = {
            binding = {
              minus = "resize smart -50";
              plus = "resize smart +50";
            };
          };
        };
      };
    };
  };
}
