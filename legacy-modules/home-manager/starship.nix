{ config, lib, ... }:
let cfg = config.ryk.starship;
in {
  options.ryk.starship = {
    enable = lib.mkEnableOption "Enable starship home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;

      settings = {
        hostname = { ssh_symbol = ""; };
        nix_shell = {
          format = "[$name]($style)";
          heuristic = true;
        };
        kubernetes = {
          disabled = false;
          detect_env_vars = [ "K8S" "HOMELAB" ];
        };
      };
    };
  };
}
