{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.helix;
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "helix";
    rev = "adc26c3cdeba268962e1aef2c8acf9a691abd76e";
    sha256 = "sha256-6SIjwpfUuEmdYrwiYA5f1StFAAFmIsAY+H/Day4SMHc=";
  };
in {
  options.rhx.helix = {
    enable = lib.mkEnableOption "Enable helix home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = { theme = "catppuccin_mocha"; };
    };

    home.file = {
      ".config/helix/themes/catppuccin_mocha.toml".source =
        "${catppuccin}/themes/default/catppuccin_mocha.toml";
    };

  };
}
