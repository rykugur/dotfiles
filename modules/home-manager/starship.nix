{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.starship;

  flavor = "mocha";
  catppuccin-starship = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "starship";
    rev = "5906cc369dd8207e063c0e6e2d27bd0c0b567cb8";
    sha256 = "sha256-FLHjbClpTqaK4n2qmepCPkb8rocaAo3qeV4Zp1hia0g=";
  };
  configTOML = builtins.fromTOML
    (builtins.readFile "${catppuccin-starship}/starship.toml");
in {
  options.rhx.starship = {
    enable = lib.mkEnableOption "Enable starship home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;

      settings = configTOML // {
        palette = "catppuccin_${flavor}";
        hostname = { ssh_symbol = ""; };
        nix_shell = {
          format = "[$name]($style)";
          heuristic = true;
        };
        kubernetes = {
          disabled = false;
          detect_env_vars = [ "k8s" "homelab" ];
        };
      };
    };
  };
}
