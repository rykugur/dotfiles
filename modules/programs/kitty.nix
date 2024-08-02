{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.kitty;
in {
  options.modules.programs.kitty.enable = lib.mkEnableOption "Enable kitty";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # TODO: better understand this, appears to be required to get the HM config
      config, pkgs, ... }: {
        home.packages = with pkgs; [ kitty ];

        home.file = {
          ".config/kitty" = {
            # source = ../../configs/kitty;
            source = config.lib.file.mkOutOfStoreSymlink
              "${config.home.homeDirectory}/.dotfiles/configs/kitty";
            recursive = true;
          };
        };
      };
  };
}
