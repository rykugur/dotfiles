{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.swayfx;
  swayfx = inputs.swayfx.packages.x86_64-linux.default;
in {
  options = {
    swayfx.enable = lib.mkEnableOption "Enable swayFX";
  };

  config = lib.mkIf cfg.enable {
    gbar.enable = true;
    wayland.enable = true;

    wayland.windowManager.sway = {
      enable = true;
      checkConfig = false;
      package = swayfx;
    };
  };
}
