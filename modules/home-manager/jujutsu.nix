{ config, lib, ... }:
let cfg = config.rhx.jujutsu;
in {
  options.rhx.jujutsu = {
    enable = lib.mkEnableOption "Enable jujutsu home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      # settings = {};
    };
  };
}
