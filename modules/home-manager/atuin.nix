{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.atuin;
  # catppuccin = pkgs.fetchFromGitHub {
  #   owner = "catppuccin";
  #   repo = "atuin";
  #   rev = "abfab12de743aa73cf20ac3fa61e450c4d96380c";
  #   sha256 = "sha256-t/Pq+hlCcdSigtk5uzw3n7p5ey0oH/D5S8GO/0wlpKA=";
  # };
in {
  options.rhx.atuin = {
    enable = lib.mkEnableOption "Enable atuin home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package = inputs.atuin.packages.${pkgs.system}.default;

      enableNushellIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    home.file = {
      ".config/atuin/themes/catppuccin-mocha-blue.toml" = {
        source =
          "${pkgs.catppuccin-ports.atuin}/themes/mocha/catppuccin-mocha-blue.toml";
      };
    };
  };
}
