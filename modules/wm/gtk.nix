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
          name = "catppuccin-mocha-compact-blue-dark";
          package = pkgs.catppuccin-gtk.override {
            accents = [ "blue" ];
            size = "compact";
            tweaks = [ "rimless" ];
            variant = "mocha";
          };
        };

        cursorTheme = let package = pkgs.catppuccin-cursors;
        in {
          # name = "Bibata-Modern-Ice";
          # package = pkgs.bibata-cursors;
          name = package.outputName;
          inherit package;
        };

        iconTheme = let package = pkgs.catppuccin-papirus-folders;
        in {
          # name = "Vimix-dark";
          # package = pkgs.vimix-icon-theme;
          name = package.outputName;
          inherit package;
        };

        gtk2.extraConfig = ''
          gtk-application-prefer-dark-theme=1
        '';

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
