{ config, lib, pkgs, ... }:
let cfg = config.rhx.wezterm;
in {
  options.rhx.wezterm = {
    enable = lib.mkEnableOption "Enable wezterm home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wezterm ];

    home.file = {
      ".config/wezterm" = {
        source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/.dotfiles/configs/wezterm";
        recursive = true;
      };
    };
  };
}
