{ ... }:
{
  flake.modules.homeManager.firefox =
    { config, lib, pkgs, ... }:
    {
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
                    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
        };
      };
    };
}
