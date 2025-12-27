{ config, lib, ... }:
let cfg = config.ryk.carapace;
in {
  options.ryk.carapace = {
    enable = lib.mkEnableOption "Enable carapace home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.carapace = {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
  };
}
