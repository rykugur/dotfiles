{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.ags;
in {
  options.rhx.ags = {
    enable = lib.mkEnableOption "Enable ags home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    imports = [ inputs.ags.homeManagerModules.default ];
    programs.ags = {
      enable = true;

      configDir = ../../configs/ags;

      # additional packages to add to gjs's runtime
      extraPackages = with pkgs; [ gtksourceview webkitgtk accountsservice ];
    };
  };
}
