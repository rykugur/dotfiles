{ inputs
, lib
, config
, ...
}: {
  programs.neovim = {
    enable = true;
  };

  home.file.".config/nvim" = {
    source = ../../../configs/nvim/lazyvim;
    recursive = true;
    force = true;
  };
}
