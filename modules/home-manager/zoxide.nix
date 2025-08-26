{ config, lib, ... }:
let cfg = config.rhx.zoxide;
in {
  options.rhx.zoxide = {
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
