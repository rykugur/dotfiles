{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.nushell;
  nu-scripts = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nu_scripts";
    rev = "e380c8a355b4340c26dc51c6be7bed78f87b0c71";
    sha256 = "sha256-b2AeWiHRz1LbiGR1gOJHBV3H56QP7h8oSTzg+X4Shk8=";
  };
in {
  options.rhx.nushell = {
    enable = lib.mkEnableOption "Enable nushell home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.nushell = {
      enable = true;
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
        source ${nu-scripts}/themes/nu-themes/catppuccin-mocha.nu
        source ${nu-scripts}/custom-menus/zoxide-menu.nu
        source ~/.dotfiles/configs/nu/config.nu
      '';
    };

    programs.direnv.enableNushellIntegration = true;
    programs.carapace.enableNushellIntegration = true;
    programs.starship.enableNushellIntegration = true;
    programs.zoxide.enableNushellIntegration = true;
  };
}
