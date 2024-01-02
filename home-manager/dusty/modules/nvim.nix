{ inputs
, lib
, config
, ...
}: {
  programs.neovim = {
    enable = true;
  };

  home.file = {
    ".config/nvim/init.lua" = {
      source = ../../../configs/nvim/lazyvim/init.lua;
    };
    ".config/nvim/lua" = {
      source = ../../../configs/nvim/lazyvim/lua;
      recursive = true;
    };
  };

  # home.file.".config/nvim" = {
  #   source = ../../../configs/nvim/lazyvim;
  #   recursive = true;
  # };
}
