{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.modules.wm.ags;
in {
  options.modules.wm.ags.enable = lib.mkEnableOption "enable ags";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      imports = [ inputs.ags.homeManagerModules.default ];
      programs.ags = {
        enable = true;

        # additional packages to add to gjs's runtime
        extraPackages = with pkgs; [ gtksourceview webkitgtk accountsservice ];
      };
    };
  };

}
