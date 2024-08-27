{ config, lib, pkgs, username, ... }:
let cfg = config.modules.gaming.wow;
in {
  options.modules.gaming.wow.enable =
    lib.mkEnableOption "enable World of Warcraft module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ wowup-cf ];
    };
  };
}
