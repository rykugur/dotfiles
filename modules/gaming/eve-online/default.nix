{ config, lib, username, ... }:
let cfg = config.rhx.gaming.eve-online;
in {

  options.rhx.gaming.eve-online.enable =
    lib.mkEnableOption "Enable EVE Online module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
