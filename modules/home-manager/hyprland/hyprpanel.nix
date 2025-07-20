{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.hyprpanel;
in {
  options.rhx.hyprpanel = {
    enable = lib.mkEnableOption "Enable hyprpanel home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;

      # eventually I'll move this to here, but for now I'll just use a out-of-store symlink
      # to allow for faster iteration
      # layout = {
      #   "bar.layouts" = {
      #     "0" = {
      #       left = [ "dashboard" "workspaces" "windowtitle" ];
      #       middle = [ "media" ];
      #       right = [ "volume" "systray" "clock" "notifications" ];
      #     };
      #     "1" = {
      #       left = [ "dashboard" "workspaces" "windowtitle" ];
      #       middle = [ ];
      #       right = [ "volume" "systray" "clock" "notifications" ];
      #     };
      #   };
      # };

      # settings = {
      #   # theme = { bar.floating = true; };
      # };
    };

    # f that - old fashioned symlink for now for the FASTEST iteration
    # home.file = {
    #   ".config/hyprpanel" = {
    #     source = config.lib.file.mkOutOfStoreSymlink
    #       "${config.home.homeDirectory}/.dotfiles/configs/hyprpanel";
    #     recursive = true;
    #   };
    # };
  };
}
