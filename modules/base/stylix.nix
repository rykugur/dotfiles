{ config, lib, pkgs, ... }:
let cfg = config.ryk.stylix;
in {
  options.ryk.stylix.enable = lib.mkEnableOption "Enable stylix base module.";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;

      base16Scheme =
        "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      cursor = {
        enable = true;
        package = pkgs.phinger-cursors;
        name = "phinger-cursors-dark";
        size = 32;
      };

      fonts = {
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };

        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };

        monospace = {
          package = pkgs.nerd-fonts.caskaydia-mono;
          name = "CaskaydiaCove NFM";
        };

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };
    };

    # stylix.image = ../../configs/wallpapers/wallpaper.png;
  };
}
