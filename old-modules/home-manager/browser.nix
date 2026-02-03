{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.ryk.browser;
  zenPkg =
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  imports = [ inputs.zen-browser.homeModules.default ];

  options.ryk.browser = {
    enable = lib.mkEnableOption "Enable browser home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      package = zenPkg;
    };

    stylix.targets.zen-browser.enable =
      false; # this is borked, just manual for now

    home.packages = [ pkgs.google-chrome ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = let zenDesktop = "zen-beta.desktop";
        in {
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
