{ inputs, ... }:
{
  flake.modules.homeManager.zen-browser =
    { config, lib, pkgs, ... }:
    let
      zenPkg = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      imports = [ inputs.zen-browser.homeModules.default ];

      programs.zen-browser = {
        enable = true;
        package = zenPkg;
      };

      stylix.targets.zen-browser.enable = false; # this is borked, just manual for now

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications =
            let
              zenDesktop = "zen-beta.desktop";
            in
            {
              "application/pdf" = [ zenDesktop ];
              "text/html" = [ zenDesktop ];
              "x-scheme-handler/about" = [ zenDesktop ];
              "x-scheme-handler/unknown" = [ zenDesktop ];
              "x-scheme-handler/chrome" = [ zenDesktop ];
              "application/x-extension-htm" = [ zenDesktop ];
              "application/x-extension-html" = [ zenDesktop ];
              "application/x-extension-shtml" = [ zenDesktop ];
              "application/xhtml+xml" = [ zenDesktop ];
              "application/x-extension-xhtml" = [ zenDesktop ];
              "application/x-extension-xht" = [ zenDesktop ];

              "x-scheme-handler/http" = zenDesktop;
              "x-scheme-handler/https" = zenDesktop;
            };
        };
      };
    };
}
