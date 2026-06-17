{ config, lib, username, ... }:
let cfg = config.ryk.noctalia;
in {
  options.ryk.noctalia = {
    enable = lib.mkEnableOption "Enable noctalia custom quickshell module.";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
