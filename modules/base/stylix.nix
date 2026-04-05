{ ... }:
let
  stylixModule =
    { lib, options, pkgs, ... }:
    {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        fonts = {
          serif     = { package = pkgs.dejavu_fonts;               name = "DejaVu Serif"; };
          sansSerif = { package = pkgs.dejavu_fonts;               name = "DejaVu Sans"; };
          monospace = { package = pkgs.nerd-fonts.caskaydia-mono;  name = "CaskaydiaCove NFM"; };
          emoji     = { package = pkgs.noto-fonts-color-emoji;     name = "Noto Color Emoji"; };
        };
      } // lib.optionalAttrs (options.stylix ? icons) {
        icons = {
          enable = true;
          package = pkgs.papirus-icon-theme;
          dark = "Papirus-Dark";
          light = "Papirus-Light";
        };
      } // lib.optionalAttrs (options.stylix ? cursor) {
        # catppuccin-cursors builds from source, takes 30+ min; not cached on nixpkgs unstable
        # cursor = {
        #   package = pkgs.catppuccin-cursors.mochaDark;
        #   name = "catppuccin-mocha-dark-cursors";
        #   size = 32;
        # };
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 32;
        };
      };
    };
in
{
  flake.modules.nixos.stylix = stylixModule;
  flake.modules.darwin.stylix = stylixModule;
}
