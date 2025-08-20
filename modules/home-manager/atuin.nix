{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.atuin;
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
