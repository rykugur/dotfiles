{ config, lib, username, ... }:
let cfg = config.modules.programs.wezterm;
in {
  options.modules.programs.wezterm.enable = lib.mkEnableOption "enable wezterm";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # TODO: better understand this, appears to be required to get the HM config
      config, pkgs, ... }: {
        home.packages = [ pkgs.wezterm ];

        home.file = {
          ".config/wezterm" = {
            source = config.lib.file.mkOutOfStoreSymlink
              "${config.home.homeDirectory}/.dotfiles/configs/wezterm";
            recursive = true;
          };
        };
      };
  };
}
