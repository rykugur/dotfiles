{
  lib,
  nixosConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf nixosConfig.ryk.gaming.jackify.enable {
    home.packages = with pkgs; [
      jackify
    ];

    # xdg = {
    #   desktopEntries.jackify = {
    #     name = "Jackify";
    #     exec = "${pkgs.jackify}/bin/jackify %u";
    #     icon = "jackify";
    #     type = "Application";
    #     terminal = false;
    #     categories = [
    #       "Utility"
    #       "Game"
    #     ];
    #     mimeType = [ "x-scheme-handler/jackify" ];
    #     comment = "Wabbajack Modlist Installer for Linux";
    #   };

    #   mimeApps = {
    #     defaultApplications = {
    #       "x-scheme-handler/jackify" = [ "jackify.desktop" ];
    #     };
    #   };
    # };
  };
}
