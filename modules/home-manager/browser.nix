{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.browser;
  zen-pkg = inputs.zen-browser.packages.${pkgs.system}.default;
  urlHandlerScript = pkgs.writeScript "url_handler" ''
    #!${pkgs.bash}/bin/bash

    URL="$1"

    echo $URL

    if [[ "$URL" == *"neo.bullx.io"* ]]; then
        ${pkgs.google-chrome}/bin/google-chrome-stable "$URL"
    else
        ${zen-pkg}/bin/zen "$URL"
    fi
  '';
in {
  options.rhx.browser = {
    enable = lib.mkEnableOption "Enable browser home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.enable = true;

    home.packages =
      lib.optionals (lib.hasAttr pkgs.system inputs.zen-browser.packages)
      [ zen-pkg ] ++ [ pkgs.google-chrome ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = {
          "application/pdf" = [ "zen.desktop" ];
          "inode/directory" = [ "thunar.desktop" ];
          "text/html" = [ "zen.desktop" ];
          "x-scheme-handler/about" = [ "zen.desktop" ];
          "x-scheme-handler/unknown" = [ "zen.desktop" ];
          "x-scheme-handler/chrome" = [ "zen.desktop" ];
          "application/x-extension-htm" = [ "zen.desktop" ];
          "application/x-extension-html" = [ "zen.desktop" ];
          "application/x-extension-shtml" = [ "zen.desktop" ];
          "application/xhtml+xml" = [ "zen.desktop" ];
          "application/x-extension-xhtml" = [ "zen.desktop" ];
          "application/x-extension-xht" = [ "zen.desktop" ];

          # TODO: figure out why this doesn't work
          # "x-scheme-handler/http" = "${urlHandlerScript}";
          # "x-scheme-handler/https" = "${urlHandlerScript}";
          "x-scheme-handler/http" = [ "zen.desktop" ];
          "x-scheme-handler/https" = [ "zen.desktop" ];
        };
      };
    };
  };
}
