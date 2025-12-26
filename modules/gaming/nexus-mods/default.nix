{ config, lib, username, ... }:
let cfg = config.rhx.gaming.nexus-mods;
in {

  options.rhx.gaming.nexus-mods.enable =
    lib.mkEnableOption "Enable Nexus Mods module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
