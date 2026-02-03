{ config, inputs, lib, pkgs, ... }:
let cfg = config.ryk.atuin;
in {
  options.ryk.atuin = {
    enable = lib.mkEnableOption "Enable atuin home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package =
        inputs.atuin.packages.${pkgs.stdenv.hostPlatform.system}.default;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;

      flags = [ "--disable-up-arrow" ];
    };
  };
}
