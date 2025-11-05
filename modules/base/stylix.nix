{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.stylix;
in {
  imports = [ inputs.stylix.nixosModules.stylix ];

  options.rhx.stylix.enable = lib.mkEnableOption "Enable stylid nixOS module.";

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;

      base16Scheme =
        "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      cursor = {
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
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = 10;
          terminal = 13;
          desktop = 10;
          popups = 10;
        };
      };

      image = ../../configs/wallpapers/wallpaper.png;

      targets = { opencode.enable = false; };
    };
  };
}
