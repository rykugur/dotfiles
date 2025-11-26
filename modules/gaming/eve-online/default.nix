{ config, lib, username, ... }:
let cfg = config.rhx.eve-online;
in {

  options.rhx.eve-online.enable = lib.mkEnableOption "Enable EVE Online module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
