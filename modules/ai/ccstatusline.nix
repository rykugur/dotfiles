{ ... }:
{
  flake.modules.homeManager.ccstatusline =
    { config, ... }:
    {
      home.file = {
        # out of store so we can make changes to it that are reflected in git
        # ... at least until it's "done"
        # derp
        # TODO: remove `config.lib.file.mkOutOfStoreSymlink` when ready
        ".config/ccstatusline" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/ccstatusline/settings.json";
          recursive = true;
        };
        # ".config/nvim" = {
        #   source = config.lib.file.mkOutOfStoreSymlink
        #     "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim";
        #   recursive = true;
        # };
      };
    };
}
