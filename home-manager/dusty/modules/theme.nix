{ config, inputs, lib, pkgs, ... }: {

  home.packages = with pkgs; [
    fira
    (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; })

    catppuccin-gtk
    matcha-gtk-theme
    papirus-icon-theme
    volantes-cursors
  ];


  gtk = {
    enable = true;

    font.name = "FiraCode Nerd Font Mono 10";

    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "compact";
        tweaks = [ "rimless" "black" ];
        variant = "mocha";
      };
    };

    cursorTheme = {
      name = "Bibata";
      package = pkgs.bibata-cursors;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  #gtk = {
  #  enable = true;
  #  cursorTheme = {
  #    name = "Volantes";
  #    package = pkgs.volantes-cursors;
  #  };
  #  theme = {
  #    name = "Catppuccin-Mocha-Compact-Blue-Dark";
  #    package = pkgs.catppuccin-gtk.override {
  #      accents = [ "blue" ];
  #      size = "compact";
  #      tweaks = [ "rimless" "black" ];
  #      variant = "mocha";
  #    };
  #  };
  #};

}
