{ lib, nixosConfig, pkgs, ... }: {
  config = lib.mkIf nixosConfig.ryk.dev.yaak.enable {
    home.packages = [ pkgs.yaak ];
    # xdg.desktopEntries = {
    #   yaak = {
    #     name = "yaak";
    #     genericName = "API Client";
    #     comment = "Play with APIs, intuitively";
    #     icon = "yaak-app";
    #     exec = "${pkgs.yaak}/bin/yaak-app";
    #     terminal = false;
    #     categories = [ "Development" ];
    #     type = "Application";
    #     # settings = { StartupWmClass = "yaak-app"; };
    #   };
    # };
  };
}
