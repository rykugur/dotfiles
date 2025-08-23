{ config, lib, pkgs, ... }:
let cfg = config.rhx.nvim;
in {
  options.rhx.nvim = {
    enable = lib.mkEnableOption "Enable nvim home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = { enable = true; };

    home = {
      packages = with pkgs; [ fd lazygit neovide nixfmt-classic ripgrep ];

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
