{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.vivaldi;
  catppuccin-mocha-blue-vivaldi-theme = pkgs.fetchzip {
    url =
      "https://github.com/catppuccin/vivaldi/releases/download/1.0.0-ctpv2/Catppuccin.Mocha.Blue.zip";
    sha256 = "sha256-sE3UL8NHg1mXnciuOcIVt5vdjOsgYEhtEW04NDuL6rI=";

    stripRoot = false;
  };
in {
  options.modules.programs.vivaldi.enable =
    lib.mkEnableOption "Enable Vivaldi.";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ vivaldi ];

      home.file = {
        ".vivald-themes/catppuccin-mocha-blue/" = {
          source = "${catppuccin-mocha-blue-vivaldi-theme}";
          recursive = true;
        };
      };

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "text/html" = [ "vivaldi.desktop" ];
            "x-scheme-handler/http" = [ "vivaldi.desktop" ];
            "x-scheme-handler/https" = [ "vivaldi.desktop" ];
            "x-scheme-handler/about" = [ "vivaldi.desktop" ];
            "x-scheme-handler/unknown" = [ "vivaldi.desktop" ];
            "application/pdf" = [ "vivaldi.desktop" ];
          };
        };
      };
    };
  };
}
