{ self, ... }:
{
  flake.nixosModules.nexus-mods =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.nexus-mods ];
    };

  flake.homeModules.nexus-mods =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nexusmods-app-unfree ];

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
