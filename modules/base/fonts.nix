{ config, lib, pkgs, ... }:
let cfg = config.rhx.fonts;
in {
  options.rhx.fonts.enable = lib.mkEnableOption "Enable certain fonts";

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.zed-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
    ];
  };
}
