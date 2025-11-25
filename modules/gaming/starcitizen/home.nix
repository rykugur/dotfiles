{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.starcitizen;
  gameglass =
    inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.gameglass;
in {
  options.rhx.starcitizen = {
    enable = lib.mkEnableOption "Enable starcitizen home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ opentrack gameglass ];

    xdg.desktopEntries.gameglass = {
      name = "GameGlass";
      icon = "gameglass";
      exec = "${gameglass}/bin/gameglass";
      terminal = false;
      type = "Application";
      categories = [ "Game" "Utility" ];
    };
  };
}
