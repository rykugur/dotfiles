{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.term.nushell;
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
  ez = import ./ez;
in {
  options.modules.programs.term.nushell.enable =
    lib.mkEnableOption "Enable nushell.";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.nushell = {
        enable = true;
        environmentVariables = ez.env;
        extraConfig = ''
          use ${nupm}/nupm
          source ${nu-scripts}/themes/nu-themes/catppuccin-mocha.nu
        '';
        shellAliases = ez.aliases;
      };

      programs.starship = {
        enable = true;
        enableNushellIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
