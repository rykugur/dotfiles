{ config, lib, ... }:
let cfg = config.ryk.zoxide;
in {
  options.ryk.zoxide = {
    enable = lib.mkEnableOption "Enable zoxide home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
  };
}
