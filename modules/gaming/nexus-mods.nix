{ ... }:
{
  flake.modules.homeManager.nexus-mods =
    { pkgs, ... }:
    {
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
