{ config, lib, username, ... }:
let cfg = config.ryk.gaming.nexus-mods;
in {

  options.ryk.gaming.nexus-mods.enable =
    lib.mkEnableOption "Enable Nexus Mods module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
