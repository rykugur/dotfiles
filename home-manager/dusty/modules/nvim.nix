{ inputs
, lib
, config
, ...
}: {
  programs.neovim = {
    enable = true;
  };

  home.file = {
    ".config/nvim/init.lua".source = ../../../configs/nvim/lazyvim/init.lua;
    ".config/nvim/lua" = {
      source = ../../../configs/nvim/lazyvim/lua;
      recursive = true;
    };
    ".config/nvim/lazy-lock.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim/lazy-lock.json";
    ".config/nvim/lazyvim.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim/lazyvim.json";
  };
}
