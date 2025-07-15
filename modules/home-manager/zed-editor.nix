{ config, lib, ... }:
let cfg = config.rhx.zed-editor;
in {
  options.rhx.zed-editor = {
    enable = lib.mkEnableOption "Enable zed-editor home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    # home.packages = [];
    programs.zed-editor = {
      enable = true;
      extensions = [ "nix" "catppuccin" ];
      userSettings = {
        helix_mode = true;
        theme = "Catppuccin Mocha";
      };
    };
  };
}
