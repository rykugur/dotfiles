{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.programs.nvim;
in {
  options = {
    programs.nvim.enable = lib.mkEnableOption "Enable neovim";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        pkgs.alejandra
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
    };
  };
}
