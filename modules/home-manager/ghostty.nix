{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.ghostty;
  ghostty-pkg = inputs.ghostty.packages.${pkgs.system}.default;
  useWindowDecoration = if pkgs.stdenv.isDarwin then "true" else "false";
in {
  options.rhx.ghostty = {
    enable = lib.mkEnableOption "Enable ghostty home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    # installed via brew _for now_ (build failing on nixpkgs)
    home.packages = lib.mkIf (!pkgs.stdenv.isDarwin) [ ghostty-pkg ];
    home.file = {
      ".config/ghostty/config" = {
        text = ''
          font-family = ZedMono NFM
          font-family-bold = ZedMono NFM Bold
          font-family-italic = ZedMono NFM Italic
          font-family-bold-italic = ZedMono NFM Bold Italic
          font-size = 14

          gtk-single-instance = true

          window-decoration = ${useWindowDecoration}

          theme = catppuccin-mocha

          copy-on-select = clipboard

          working-directory = home

          window-height = 40
          window-width = 160

          adw-toast = false

          command = ${pkgs.nushell}/bin/nu --login
        '';
      };
    };
  };
}
