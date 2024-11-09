{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.term.nushell;
  nu-scripts = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nu_scripts";
    rev = "e380c8a355b4340c26dc51c6be7bed78f87b0c71";
    sha256 = lib.fakeSha256;
  };
  nupm = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nupm";
    rev = "7e3e5779ff86a1b8dadcf7a90eee2e3dcfe449df";
    sha256 = lib.fakeSha256;
  };
in {
  options.modules.programs.term.nushell.enable =
    lib.mkEnableOption "Enable nushell.";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nushell ];
    users.users.${username}.shell = pkgs.nushell;

    home-manager.users.${username} = {
      # home.packages = with pkgs; [ ];

      programs.nushell = {
        enable = true;
        shellAliases = { ll = "ls -al"; };
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
