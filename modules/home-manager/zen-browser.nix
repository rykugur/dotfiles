{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.zen-browser;
in {
  options.rhx.zen-browser = {
    enable = lib.mkEnableOption "Enable zen-browser home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages.${pkgs.system}.default ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = {
          "text/html" = [ "zen.desktop" ];
          "x-scheme-handler/http" = [ "zen.desktop" ];
          "x-scheme-handler/https" = [ "zen.desktop" ];
          "x-scheme-handler/about" = [ "zen.desktop" ];
          "x-scheme-handler/unknown" = [ "zen.desktop" ];
          "application/pdf" = [ "zen.desktop" ];
        };
      };
    };
  };
}
