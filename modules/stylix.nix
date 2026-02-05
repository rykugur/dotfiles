{ ... }:
{
  flake.nixosModules.stylix =
    {
      pkgs,
      ...
    }:
    {
      stylix = {
        enable = true;

        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

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
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };

      # stylix.image = ../../configs/wallpapers/wallpaper.png;
    };
}
