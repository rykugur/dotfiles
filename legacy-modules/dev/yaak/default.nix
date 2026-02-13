{ config, lib, username, ... }:
let cfg = config.ryk.dev.yaak;
in {
  options.ryk.dev.yaak.enable = lib.mkEnableOption "Enable yaak module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
