{ ... }:
{
  flake.modules.homeManager.wezterm =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.wezterm ];

      home.file = {
        ".config/wezterm" = {
          source = config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/.dotfiles/configs/wezterm";
          recursive = true;
        };
      };
    };
}
