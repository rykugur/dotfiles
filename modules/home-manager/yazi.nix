{ config, lib, pkgs, ... }:
let cfg = config.rhx.yazi;
in {
  options.rhx.yazi = {
    enable = lib.mkEnableOption "Enable yazi home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
  };
}
