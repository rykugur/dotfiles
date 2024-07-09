{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.firefox;
  plexDesktop = pkgs.makeDesktopItem {
    name = "Plex Media Player (Firefox)";
    desktopName = "Plex Media Player (Firefox)";
    exec = "${pkgs.firefox}/bin/firefox --P plex";
  };
  ArcWTF = pkgs.stdenv.mkDerivation rec {
    name = "arcWTF";
    version = "1.2-firefox";

    src = pkgs.fetchFromGitHub {
      owner = "KiKaraage";
      repo = "ArcWTF";
      rev = "v${version}";
      hash = "sha256-c1md5erWAqfmpizNz2TrM1QyUnnkbi47thDBMjHB4H0=";
    };

    dontPatch = true;
    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      mkdir -p $out/chrome
      cp -r $src/* $out/chrome
    '';
  };
in {
  options.modules.programs.firefox.enable =
    lib.mkEnableOption "Enable firefox (wrapper) module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [ plexDesktop ];

      programs.firefox = {
        enable = true;
        package =
          pkgs.firefox.override { cfg = { enableGnomeExtensions = true; }; };

        profiles = {
          default = {
            id = 0;
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "svg.context-properties.content.enabled" = true;
              "uc.tweak.popup-search" = true;
              "uc.tweak.longer-sidebar" = true;
            };
            isDefault = true;
            search = {
              force = true;
              default = "Google";
              order = [ "Google" ];
              engines = {
                "Nix Packages" = {
                  urls = [{
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }];
                  icon =
                    "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = [ "@np" ];
                };
                "NixOS Wiki" = {
                  urls = [{
                    template =
                      "https://nixos.wiki/index.php?search={searchTerms}";
                  }];
                  iconUpdateURL = "https://nixos.wiki/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@nw" ];
                };
                "Home-manager Options" = {
                  urls = [{
                    template =
                      "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";
                  }];
                  iconUpdateURL =
                    "https://home-manager-options.extranix.com/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@hm" ];
                };
                "Bing".metaData.hidden = true;
                "Google".metaData.alias =
                  "@g"; # builtin engines only support specifying one additional alias
              };
            };
          };
          plex = {
            id = 1;
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
          };
        };
      };

      home.file = {
        ".mozilla/firefox/default/chrome" = {
          source = "${ArcWTF}/chrome";
          recursive = true;
        };
      };

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
    };
  };
}
