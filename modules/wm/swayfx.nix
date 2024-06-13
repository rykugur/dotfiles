{
  config,
  lib,
  inputs,
  username,
  ...
}: let
  cfg = config.wm.swayfx;
  swayfx = inputs.swayfx.packages.x86_64-linux.default;
in {
  options.wm.swayfx.enable = lib.mkEnableOption "Enable swayFX";

  config = lib.mkIf cfg.enable {
    programs.sway = {
      enable = true;
      package = swayfx.overrideAttrs (old: {passthru.providedSessions = ["sway"];});
      wrapperFeatures.gtk = true;
    };

    services.gnome.gnome-keyring.enable = true;

    home-manager.users.${username} = {
      wayland.windowManager.sway = {
        enable = true;
        checkConfig = false;
        package = swayfx;
      };
    };
  };
}
