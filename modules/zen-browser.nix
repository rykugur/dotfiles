{ inputs, self, ... }:
{
  flake.nixosModules.zen-browser =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.zen-browser ];
    };

  flake.homeModules.zen-browser =
    { pkgs, ... }:
    let
      zenPkg = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      programs.zen-browser = {
        enable = true;
        package = zenPkg;
      };

      # this is borked, just manual for now
      stylix.targets.zen-browser.enable = false;

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
