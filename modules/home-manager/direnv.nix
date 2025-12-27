{ config, lib, ... }:
let cfg = config.ryk.direnv;
in {
  options.ryk.direnv = {
    enable = lib.mkEnableOption "Enable direnv home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;

      nix-direnv.enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
  };
}
