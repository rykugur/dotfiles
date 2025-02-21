{ config, lib, ... }:
let cfg = config.rhx.aerospace;
in {
  options.rhx.aerospace.enable =
    lib.mkEnableOption "Enable aerospace darwin module";

  config = lib.mkIf cfg.enable {
    system = {
      defaults = {
        dock = { expose-group-apps = true; };
        spaces = { spans-displays = true; };
      };
    };
  };
}
