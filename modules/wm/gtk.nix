{ config, lib, pkgs, username, ... }:
let cfg = config.modules.wm.gtk;
in {
  options.modules.wm.gtk.enable = lib.mkEnableOption "Enable gtk";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        nwg-look
        catppuccin-gtk
        catppuccin-cursors
        catppuccin-papirus-folders
      ];

      gtk = {
        enable = true;

        font.name = "FiraCode Nerd Font Mono 10";

        theme = {
          name = "Adementary-dark";
          package = pkgs.adementary-theme;
          # name = "catppuccin-mocha-compact-blue-dark";
          # package = pkgs.catppuccin-gtk.override {
          #   accents = [ "blue" ];
          #   size = "compact";
          #   tweaks = [ "rimless" ];
          #   variant = "mocha";
          # };
        };

        cursorTheme = {
          name = "catppuccin-mocha-blue-cursors";
          package = pkgs.catppuccin-cursors.mochaBlue;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.catppuccin-papirus-folders.override {
            flavor = "mocha";
            accent = "blue";
          };
        };

        gtk2.extraConfig = ''
          gtk-application-prefer-dark-theme=1
        '';

        gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };

        gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
      };

      # gtk = {
      #   enable = true;
      #
      #   font.name = "FiraCode Nerd Font Mono 10";
      #
      #   catppuccin = {
      #     enable = true;
      #     flavor = "mocha";
      #     accent = "blue";
      #
      #     cursor = {
      #       enable = true;
      #       flavor = "mocha";
      #       accent = "blue";
      #     };
      #
      #     icon = {
      #       enable = true;
      #       flavor = "mocha";
      #       accent = "blue";
      #     };
      #   };
      #
      #   gtk2.extraConfig = ''
      #     gtk-application-prefer-dark-theme=1
      #   '';
      #
      #   gtk3.extraConfig = {
      #     Settings = ''
      #       gtk-application-prefer-dark-theme=1
      #     '';
      #   };
      #
      #   gtk4.extraConfig = {
      #     Settings = ''
      #       gtk-application-prefer-dark-theme=1
      #     '';
      #   };
      # };
    };
  };
}
