{ self, ... }:
{
  flake.nixosModules.thunar =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.thunar ];
    };

  flake.homeModules.thunar =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ xfce.thunar ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "inode/directory" = [ "thunar.desktop" ];
          };
        };
      };
    };
}
