{ config, lib, username, pkgs, ... }:
let cfg = config.ryk.razer;
in {
  options.ryk.razer.enable = lib.mkEnableOption "Enable razer nixOS module";

  config = lib.mkIf cfg.enable {
    hardware.openrazer = {
      enable = true;
      users = [ "${username}" ];
    };

    services = { input-remapper.enable = true; };

    environment.systemPackages = with pkgs; [ piper polychromatic ];
  };
}
