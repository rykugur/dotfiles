{ config, lib, pkgs, ... }:
let cfg = config.rhx.nvim;
in {
  options.rhx.nvim = {
    enable = lib.mkEnableOption "Enable nvim home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = { enable = true; };

    home = {
      packages = with pkgs; [
        fd
        lazygit
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
}
