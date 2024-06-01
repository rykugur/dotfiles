{pkgs, ...}: {
  home.packages = with pkgs; [
    fira
    (nerdfonts.override {fonts = ["FiraCode" "FiraMono"];})

    catppuccin-gtk
    matcha-gtk-theme
    papirus-icon-theme
    volantes-cursors
  ];

  home.pointerCursor = {
    gtk.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 16;
  };

  gtk = {
    enable = true;

    font.name = "FiraCode Nerd Font Mono 10";

    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["blue"];
        size = "compact";
        tweaks = ["rimless"];
        variant = "mocha";
      };
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };

    iconTheme = {
      name = "Vimix-dark";
      package = pkgs.vimix-icon-theme;
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
}
