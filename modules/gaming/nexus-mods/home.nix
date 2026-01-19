{
  lib,
  nixosConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf nixosConfig.ryk.gaming.nexus-mods.enable {
    home.packages = with pkgs; [ nexusmods-app-unfree ];

    nixpkgs.config.permittedInsecurePackages = [
      "nexusmods-app-unfree-0.21.1"
    ];

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
