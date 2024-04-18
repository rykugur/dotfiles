{ pkgs, ... }:
let
  plexDesktop = pkgs.makeDesktopItem {
    name = "Plex Media Player";
    desktopName = "Plex Media Player";
    exec = "${pkgs.firefox}/bin/firefox --P plex";
  };
in
{
  home.packages = [
    pkgs.google-chrome
    plexDesktop
  ];

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      };
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      cfg = {
        enableGnomeExtensions = true;
      };
    };

    profiles = {
      default = {
        id = 0;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        userChrome = ''
          #TabsToolbar {
            display: none;
          }
        '';
      };
      plex = {
        id = 1;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        userChrome = ''
          #TabsToolbar {
            display: none;
          }
        '';
      };
    };
  };
}
