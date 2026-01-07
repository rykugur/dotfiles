{ config, lib, ... }:
let cfg = config.ryk.jujutsu;
in {
  options.ryk.jujutsu = {
    enable = lib.mkEnableOption "Enable jujutsu home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        ui = { default-command = "status"; };
        user = {
          name = "rykugur";
          email = "rollhax@gmail.com";
        };
      };
    };
  };
}
