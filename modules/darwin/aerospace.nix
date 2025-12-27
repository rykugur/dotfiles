{ config, lib, ... }:
let cfg = config.ryk.aerospace;
in {
  options.ryk.aerospace.enable =
    lib.mkEnableOption "Enable aerospace darwin module";

  config = lib.mkIf cfg.enable {
    # services.jankyborders = {
    #   enable = true;
    #   active_color = "0xffe1e3e4";
    #   inactive_color = "0xff494d64";
    #   width = 10.0;
    # };
    system = {
      defaults = {
        dock = { expose-group-apps = true; };
        spaces = { spans-displays = true; };
      };
    };
  };
}
