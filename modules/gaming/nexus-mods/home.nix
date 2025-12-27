{ lib, nixosConfig, pkgs, ... }: {
  config = lib.mkIf nixosConfig.ryk.gaming.nexus-mods.enable {
    home.packages = with pkgs; [ nexusmods-app-unfree ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = {
          "x-scheme-handler/nxm" = [ "com.nexusmods.app.desktop" ];
        };
      };
    };
  };
}
