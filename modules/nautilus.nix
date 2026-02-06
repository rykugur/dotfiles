{ self, ... }:
{
  flake.nixosModules.nautilus =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.nautilus ];
    };

  flake.homeModules.nautilus =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nautilus ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          };
        };
      };
    };
}
