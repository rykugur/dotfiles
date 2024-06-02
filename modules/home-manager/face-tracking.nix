{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.faceTracking;
  faceTracking = pkgs.writeShellScriptBin "faceTracking" ''
    aitrack &disown
    opentrack &disown
  '';
in {
  options = {
    faceTracking.enable = lib.mkEnableOption "Enable AI face tracking";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.aitrack
      pkgs.opentrack
      faceTracking
    ];
  };
}
