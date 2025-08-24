{ config, lib, pkgs, ... }:
let cfg = config.rhx.bat;
in {
  options.rhx.bat = {
    enable = lib.mkEnableOption "Enable bat home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;

      extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
      config = { theme = "Catppuccin Mocha"; };
    };

    home.file = {
      ".config/bat/themes" = {
        source = pkgs.catppuccin-ports.bat;
        recursive = true;
      };
    };
  };
}
