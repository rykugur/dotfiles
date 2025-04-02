{ config, lib, pkgs, ... }:
let cfg = config.rhx.vr;
in {
  options.rhx.vr.enable = lib.mkEnableOption "Enable VR nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wlx-overlay-s ];
    programs.alvr = {
      enable = true;
      openFirewall = true;
    };

    services = {
      monado.enable = true;
      wivrn = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
