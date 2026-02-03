{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.ryk.gaming.jackify;
in
{
  options.ryk.gaming.jackify = {
    enable = lib.mkEnableOption "Enable jackify module.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
