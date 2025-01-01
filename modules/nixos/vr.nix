{ config, lib, ... }:
let cfg = config.rhx.vr;
in {
  options.rhx.vr.enable = lib.mkEnableOption "Enable VR nixOS module";

  config = lib.mkIf cfg.enable {
    programs.alvr = {
      enable = true;
      openFirewall = true;
    };
  };
}
