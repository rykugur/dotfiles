{ config, lib, username, ... }:
let cfg = config.programs.fuzzelz;
in {
  options.programs.fuzzelz.enable = lib.mkEnableOption "Enable fuzzel";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.fuzzel = {
        enable = true;
        settings = {
          # catppuccin mocha
          # TODO: can we make this better/use a fetcher?
          colors = {
            background = "1e1e2edd";
            text = "cdd6f4ff";
            match = "f38ba8ff";
            selection = "585b70ff";
            selection-match = "f38ba8ff";
            selection-text = "cdd6f4ff";
            border = "b4befeff";
          };
        };
      };
    };
  };
}
