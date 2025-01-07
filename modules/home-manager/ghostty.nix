{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.ghostty;
  ghostty-pkg = inputs.ghostty.packages.${pkgs.system}.default;
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
          font-size = 12

          gtk-single-instance = true

          window-decoration = false

          theme = catppuccin-mocha

          command = ${pkgs.nushell}/bin/nu --login
        '';
      };
    };
  };
}
