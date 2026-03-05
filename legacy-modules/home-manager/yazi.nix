{ config, lib, pkgs, ... }:
let cfg = config.ryk.yazi;
in {
  options.ryk.yazi = {
    enable = lib.mkEnableOption "Enable yazi home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
  };
}
