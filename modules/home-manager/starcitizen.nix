{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.starcitizen;
in {
  options.rhx.starcitizen = {
    enable = lib.mkEnableOption "Enable starcitizen home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      opentrack
      inputs.nix-citizen.packages.${pkgs.system}.gameglass
    ];

    xdg.desktopEntries.gameglass = {
      name = "GameGlass";
      icon = "gameglass";
      exec =
        "${inputs.nix-citizen.packages.${pkgs.system}.gameglass}/bin/gameglass";
      terminal = false;
      type = "Application";
      categories = [ "Game" "Utility" ];
    };
  };
}
