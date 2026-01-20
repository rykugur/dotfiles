{
  config,
  lib,
  ...
}:
let
  cfg = config.ryk.misc.appimage;
in
{
  options.ryk.misc.appimage = {
    enable = lib.mkEnableOption "Enable appimage module.";
  };

  config = lib.mkIf cfg.enable {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    # home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
