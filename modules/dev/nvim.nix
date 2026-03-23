{ ... }:
{
  flake.modules.homeManager.nvim =
    { config, pkgs, ... }:
    {
      programs.neovim = { enable = true; };

      home = {
        packages = with pkgs; [ fd lazygit neovide nixfmt ripgrep ];

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
