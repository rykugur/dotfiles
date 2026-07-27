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
        # nixpkgs marks fzf.fish broken on Darwin because its fishtape test
        # suite fails on macOS; the plugin itself works, so skip the check.
        (fishPlugins.fzf-fish.overrideAttrs (old: {
          doCheck = false;
          meta = old.meta // { broken = false; };
        }))
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
