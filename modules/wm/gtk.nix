{ config, inputs, lib, username, ... }:
let cfg = config.modules.wm.gtk;
in {
  options.modules.wm.gtk.enable = lib.mkEnableOption "Enable gtk";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      imports = [ inputs.catppuccin.homeManagerModules.catppuccin ];

      gtk = {
        enable = true;

        font.name = "FiraCode Nerd Font Mono 10";

        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "blue";

          cursor = {
            enable = true;
            flavor = "mocha";
            accent = "blue";
          };

          icon = {
            enable = true;
            flavor = "mocha";
            accent = "blue";
          };
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
    };
  };
}
