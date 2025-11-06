{ config, lib, ... }:
let cfg = config.rhx.btop;
in {
  options.rhx.btop = {
    enable = lib.mkEnableOption "Enable btop home-manager module.";
    # TODO: would be cool to genericize this
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;

      settings = { theme_background = false; };
    };
  };
}
