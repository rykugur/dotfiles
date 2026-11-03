# Nushell — dendritic homeManager module
{ ... }: {
  flake.modules.homeManager.nushell = { pkgs, ... }:
    let
      nu-scripts = pkgs.fetchFromGitHub {
        owner = "nushell";
        repo = "nu_scripts";
        rev = "e380c8a355b4340c26dc51c6be7bed78f87b0c71";
        sha256 = "sha256-b2AeWiHRz1LbiGR1gOJHBV3H56QP7h8oSTzg+X4Shk8=";
      };
    in
    {
      programs.nushell = {
        enable = true;
        # Adopt the post-26.11 default early. nu is the login shell, and the
        # systemd user manager inherits its environment, so without this
        # `home.sessionVariables` reaches nothing at all - not the shell, not
        # niri, not Steam. Costs one bash subprocess per shell start.
        loadSessionVariables = true;
        extraEnv = ''
          $env.LOCAL_CONFIG_FILE = $"($nu.data-dir)/vendor/autoload/config.nu"
          $env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
          $env.config.table.show_empty = false
          $env.config.hooks.pre_prompt = (
            $env.config.hooks.pre_prompt | append (source ${nu-scripts}/nu-hooks/nu-hooks/direnv/config.nu)
          )
          source ~/.dotfiles/configs/nu/env.nu
        '';
        extraConfig = ''
          source ${nu-scripts}/custom-menus/zoxide-menu.nu
          source ~/.dotfiles/configs/nu/config.nu
        '';
      };
    };
}
