{ inputs, lib, nixosConfig, pkgs, ... }:
let
  gameglass =
    inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.gameglass;
  wineAstralPkg =
    inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.wine-astral;
in {
  config = lib.mkIf nixosConfig.rhx.starcitizen.enable {
    home.packages = with pkgs; [ opentrack-StarCitizen gameglass ];

    # lazy-mode - for opentrack
    home.file.".wine-astral".source = wineAstralPkg;

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
