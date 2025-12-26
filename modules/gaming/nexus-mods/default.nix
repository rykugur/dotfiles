{ config, lib, username, ... }:
let cfg = config.rhx.nexus-mods;
in {

  options.rhx.nexus-mods.enable = lib.mkEnableOption "Enable Nexus Mods module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
