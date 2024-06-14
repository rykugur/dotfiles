{
  lib,
  config,
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
      # TODO: better understand this, appears to be required to get the HM config
      config,
      pkgs,
      ...
    }: {
      programs.neovim = {
        enable = true;
      };

      home = {
        packages = [
          pkgs.alejandra
          pkgs.fd
          pkgs.lazygit
          pkgs.neovide
          pkgs.nodejs # required for many plugins
        ];

        file = {
          ".config/nvim" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/nvim/lazyvim";
            recursive = true;
          };
        };
      };
    };
  };
}
