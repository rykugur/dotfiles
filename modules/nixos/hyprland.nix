{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.hyprland;
in {
  options.rhx.hyprland.enable =
    lib.mkEnableOption "Enable hyprland nixOS module";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    xdg.portal = { enable = true; };
  };
}
