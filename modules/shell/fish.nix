{ ... }:
{
  flake.modules.homeManager.fish =
    { config, lib, pkgs, ... }:
    lib.mkIf (builtins.elem config.ryk.defaultShell [ "fish" "nushell" ]) {
      home.packages = with pkgs; [
        babelfish

        grc

        fishPlugins.autopair
        fishPlugins.grc
        fishPlugins.fzf-fish
        fishPlugins.z
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          source ~/.dotfiles/configs/fish/config.fish
        '';
      };

    };
}
