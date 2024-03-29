{ inputs
, lib
, config
, pkgs
, ...
}: {
  home.packages = [
    pkgs.fd
    pkgs.lazygit
    pkgs.neovide
  ];

  programs.neovim = {
    enable = true;
  };

  home.file = {
    ".config/nvim/init.lua".source = ../../configs/nvim/lazyvim/init.lua;
    ".config/nvim/lua" = {
      source = ../../configs/nvim/lazyvim/lua;
      recursive = true;
    };
  };
}
