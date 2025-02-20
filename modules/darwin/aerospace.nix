{ config, lib, ... }:
let cfg = config.rhx.aerospace;
in {
  options.rhx.aerospace.enable =
    lib.mkEnableOption "Enable aerospace darwin module";

  config = lib.mkIf cfg.enable {
    system = {
      defaults = {
        dock = {
          # for aerospace; TODO: find a better spot for this
          expose-group-apps = true;
        };
        spaces = {
          # for aerospace; TODO: find a better spot for this
          spans-displays = true;
        };
      };
    };
  };
}
