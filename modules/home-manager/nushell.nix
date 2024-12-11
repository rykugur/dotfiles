{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.nushell;
  nu-scripts = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nu_scripts";
    rev = "e380c8a355b4340c26dc51c6be7bed78f87b0c71";
    sha256 = "sha256-b2AeWiHRz1LbiGR1gOJHBV3H56QP7h8oSTzg+X4Shk8=";
  };
  nupm = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nupm";
    rev = "7e3e5779ff86a1b8dadcf7a90eee2e3dcfe449df";
    sha256 = "sha256-BNFBQ9kK2/P7mjdBqMj/8cbBPVogK0n1qcx6dx9mer8=";
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
      '';
      extraConfig = ''
        use ${nupm}/nupm
        use ${nu-scripts}/modules/rbenv/rbenv.nu *
        source ${nu-scripts}/themes/nu-themes/catppuccin-mocha.nu
        source ${nu-scripts}/custom-completions/adb/adb-completions.nu
        source ${nu-scripts}/custom-completions/bat/bat-completions.nu
        source ${nu-scripts}/custom-completions/curl/curl-completions.nu
        source ${nu-scripts}/custom-completions/docker/docker-completions.nu
        source ${nu-scripts}/custom-completions/git/git-completions.nu
        source ${nu-scripts}/custom-completions/nix/nix-completions.nu
        source ${nu-scripts}/custom-completions/npm/npm-completions.nu
        source ${nu-scripts}/custom-completions/op/op-completions.nu
        source ${nu-scripts}/custom-completions/pnpm/pnpm-completions.nu
        source ${nu-scripts}/custom-completions/rg/rg-completions.nu
        source ${nu-scripts}/custom-completions/ssh/ssh-completions.nu
        source ${nu-scripts}/custom-completions/zellij/zellij-completions.nu
        $env.config.hooks.pre_prompt = (
          $env.config.hooks.pre_prompt | append (source ${nu-scripts}/nu-hooks/nu-hooks/direnv/config.nu)
        )
        source ~/.dotfiles/configs/nu/config.nu
      '';
    };

    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };

    programs.starship = { enableNushellIntegration = true; };

    # programs.zoxide = {
    #   enable = true;
    #   enableNushellIntegration = true;
    # };

    xdg.enable = true;
  };
}
