{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.yazi;
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "5d3a1eecc304524e995fe5b936b8e25f014953e8";
    hash = "sha256-UVcPdQFwgBxR6n3/1zRd9ZEkYADkB5nkuom5SxzPTzk=";
  };
in {
  options.rhx.yazi = {
    enable = lib.mkEnableOption "Enable yazi home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableNushellIntegration = true;
    };

    home.file = {
      ".config/yazi/theme.toml" = {
        source = "${catppuccin}/themes/mocha/catppuccin-mocha-blue.toml";
      };
    };
  };
}
