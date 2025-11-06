{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.stylix;
in {
  imports = [ inputs.stylix.nixosModules.stylix ];

  options.rhx.stylix.enable = lib.mkEnableOption "Enable certain stylix";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;

      base16Scheme =
        "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

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

    stylix.image = ../../configs/wallpapers/wallpaper.png;
  };
}
