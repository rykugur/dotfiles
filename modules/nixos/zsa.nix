{ config, lib, pkgs, ... }:
let cfg = config.rhx.zsa;
in {
  options.rhx.zsa.enable = lib.mkEnableOption "Enable zsa nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.keymapp ];

    hardware.keyboard.zsa.enable = true;
  };
}
