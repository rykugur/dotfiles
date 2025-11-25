{ inputs, lib, nixosConfig, pkgs, ... }:
let
  gameglass =
    inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.gameglass;
in {
  config = lib.mkIf nixosConfig.rhx.starcitizen.enable {
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
