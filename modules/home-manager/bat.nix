{ config, lib, pkgs, ... }:
let cfg = config.ryk.bat;
in {
  options.ryk.bat = {
    enable = lib.mkEnableOption "Enable bat home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;

      extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    };
  };
}
