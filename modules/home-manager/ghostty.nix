{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.ghostty;
  ghostty-pkg = inputs.ghostty.packages.${pkgs.system}.default;
  # font = "ZedMono NFM";
  font = "CaskaydiaCove NFM";
in {
  options.rhx.ghostty = {
    enable = lib.mkEnableOption "Enable ghostty home-manager module.";
    hideWindowDecoration =
      lib.mkEnableOption "Whether to hide window-decoration or not.";
  };

  config = lib.mkIf cfg.enable {
    # installed via brew _for now_ (build failing on nixpkgs)
    home.packages = lib.mkIf (!pkgs.stdenv.isDarwin) [ ghostty-pkg ];
    home.file = {
      ".config/ghostty/config" = {
        text = ''
          font-family = ${font}
          font-family-bold = ${font} Bold
          font-family-italic = ${font} Italic
          font-family-bold-italic = ${font} Bold Italic
          font-size = 16

          theme = catppuccin-mocha

          copy-on-select = clipboard

          window-inherit-working-directory = false
          working-directory = home

          window-decoration = ${
            if cfg.hideWindowDecoration then "none" else "auto"
          }
          window-height = 50
          window-width = 125

          app-notifications = false

          command = ${pkgs.nushell}/bin/nu --login

          keybind = alt+h=goto_split:left
          keybind = alt+j=goto_split:down
          keybind = alt+k=goto_split:up
          keybind = alt+l=goto_split:right
        '';
      };
    };
  };
}
