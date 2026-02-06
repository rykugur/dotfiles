{ self, ... }:
{
  flake.nixosModules.wezterm =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.wezterm ];
    };

  flake.homeModules.wezterm =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.wezterm ];

      home.file = {
        ".config/wezterm" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/wezterm";
          recursive = true;
        };
      };
    };
}
