{ config, lib, pkgs, ... }:
let cfg = config.ryk.atuin;
in {
  options.ryk.atuin = {
    enable = lib.mkEnableOption "Enable atuin home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package = pkgs.atuin;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;

      flags = [ "--disable-up-arrow" ];
    };
  };
}
