{ config, lib, username, ... }:
let cfg = config.modules.programs.nvim;
in {
  options.modules.programs.nvim.enable = lib.mkEnableOption "Enable neovim";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # TODO: better understand this, appears to be required to get the HM config
      config, pkgs, ... }: {
        programs.neovim = { enable = true; };

        home = {
          packages = with pkgs; [
            fd
            lazygit
            neovide
            nixfmt-classic

            # below pkgs are required for plugins/updates and I'm tired of having to enter a shell to update lazyvim
            cargo
            cmake
            gcc
            go
            luaPackages.lua
            luarocks-nix
            nodejs
          ];

          file = {
            ".config/nvim" = {
              source = config.lib.file.mkOutOfStoreSymlink
                "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim";
              recursive = true;
            };
          };
        };
      };
  };
}
