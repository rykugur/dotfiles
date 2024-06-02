{
  config,
  lib,
  inputs,
  outputs,
  ...
}: let
  cfg = config.starcitizen;
in {
  # imports = [
  #   outputs.homeManagerModules.face-tracking
  # ];

  options = {
    starcitizen.enable = lib.mkEnableOption "Enable Star Citizen (nix-citizen flake).";
  };

  config = lib.mkIf cfg.enable {
    faceTracking.enable = true;

    home.packages = [
      inputs.nix-citizen.packages.x86_64-linux.star-citizen
      inputs.nix-citizen.packages.x86_64-linux.lug-helper
    ];
  };
}
