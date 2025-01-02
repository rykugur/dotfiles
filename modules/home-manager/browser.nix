{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.browser;
  zen-pkg = inputs.zen-browser.packages.${pkgs.system}.default;
  customHandler =
    "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.local/bin/custom-url-handler %U";
in {
  options.rhx.browser = {
    enable = lib.mkEnableOption "Enable browser home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.enable = true;

    home.packages =
      lib.optionals (lib.hasAttr pkgs.system inputs.zen-browser.packages)
      [ zen-pkg ] ++ [ pkgs.google-chrome ];

    home.file.".local/bin/custom-url-handler".text = ''
      #!${pkgs.bash}/bin/bash

      URL="$1"

      case "$URL" in
        *neo.bullx.io*)
          ${pkgs.google-chrome}/bin/google-chrome-stable "$URL" &
          ;;
        *)
          ${zen-pkg}/bin/zen "$URL"
          ;;
      esac
    '';
    home.file.".local/bin/custom-url-handler".executable = true;

    xdg = {
      enable = true;

      desktopEntries."custom-url-handler" = {
        name = "Custom URL Handler";
        exec = customHandler;
        terminal = false;
        type = "Application";
        categories = [ "Network" ];
        mimeType = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
      };

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

          "x-scheme-handler/http" = "custom-url-handler.desktop";
          "x-scheme-handler/https" = "custom-url-handler.desktop";
        };
      };
    };
  };
}
