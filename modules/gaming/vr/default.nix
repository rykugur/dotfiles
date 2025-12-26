{ config, lib, pkgs, ... }:
let cfg = config.rhx.gaming.vr;
in {
  options.rhx.gaming.vr.enable = lib.mkEnableOption "Enable VR module";

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

    # home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
