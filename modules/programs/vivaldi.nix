{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.vivaldi;
  catppuccin-mocha-blue-vivaldi-theme = pkgs.fetchurl {
    url =
      "https://github.com/catppuccin/vivaldi/releases/download/1.0.0-ctpv2/Catppuccin.Mocha.Blue.zip";
    sha256 = "sha256-/8tYSn/zJ9HpwcEb7tHzkwIt9OpetYMWdzWAL0x8rco=";
  };
in {
  options.modules.programs.vivaldi.enable =
    lib.mkEnableOption "Enable Vivaldi.";

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = "vivaldi-bin";
        mode = "0755";
      };
    };

    home-manager.users.${username} = {
      home.packages = with pkgs; [ vivaldi ];

      home.file = {
        ".vivald-themes/catppuccin-mocha-blue.zip" = {
          source = "${catppuccin-mocha-blue-vivaldi-theme}";
          recursive = true;
        };
      };

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "text/html" = [ "vivaldi-stable.desktop" ];
            "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
            "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
            "x-scheme-handler/about" = [ "vivaldi-stable.desktop" ];
            "x-scheme-handler/unknown" = [ "vivaldi-stable.desktop" ];
            "application/pdf" = [ "vivaldi-stable.desktop" ];
          };
        };
      };
    };
  };
}
