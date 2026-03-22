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
        format = "$all$line_break$kubernetes$line_break$character";
        hostname = { ssh_symbol = ""; };
        nix_shell = {
          format = "[$name]($style)";
          heuristic = true;
        };
        kubernetes = {
          disabled = false;
          format = "[$symbol$context( \\($namespace\\))]($style)";
        };
      };
    };
  };
}
