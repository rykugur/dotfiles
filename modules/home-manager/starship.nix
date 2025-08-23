{ config, lib, pkgs, ... }:
let cfg = config.rhx.starship;
in {
  options.rhx.starship = {
    enable = lib.mkEnableOption "Enable starship home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = let flavor = "mocha";
    in {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      enableZshIntegration = config.programs.zsh.enable;

      settings = {
        palette = "catppuccin_${flavor}";
        hostname = { ssh_symbol = ""; };
        nix_shell = {
          format = "[$name]($style)";
          heuristic = true;
        };
      } // builtins.fromTOML
        (builtins.readFile ../../configs/starship/starship-pure.toml)
        // builtins.fromTOML (builtins.readFile (pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "starship";
          rev = "5629d2356f62a9f2f8efad3ff37476c19969bd4f";
          sha256 = "sha256-nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
        } + /palettes/${flavor}.toml));
    };
  };
}
