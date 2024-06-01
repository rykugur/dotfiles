{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.alejandra
    pkgs.cargo # required for some plugins
    pkgs.fd
    pkgs.lazygit
    pkgs.neovide
    pkgs.nodejs # required for many plugins
  ];

  programs.neovim = {
    enable = true;
  };

  home.file = {
    ".config/nvim/init.lua".source = ../../configs/nvim/lazyvim/init.lua;
    ".config/nvim/lazy-lock.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim/lazy-lock.json";
    ".config/nvim/lazyvim.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim/lazy-lock.json";
    ".config/nvim/lua" = {
      source = ../../configs/nvim/lazyvim/lua;
      recursive = true;
    };
  };
}
