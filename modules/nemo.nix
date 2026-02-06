{ self, ... }:
{
  flake.nixosModules.nemo =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.nemo ];
    };

  flake.homeModules.nemo =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nemo ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "inode/directory" = [ "nemo.desktop" ];
          };
        };
      };
    };
}
