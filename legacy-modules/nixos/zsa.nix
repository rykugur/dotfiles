{ config, lib, pkgs, ... }:
let cfg = config.ryk.zsa;
in {
  options.ryk.zsa.enable = lib.mkEnableOption "Enable zsa nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.keymapp ];

    hardware.keyboard.zsa.enable = true;
  };
}
