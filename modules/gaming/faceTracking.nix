{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.programs.faceTracking;
  faceTracking = pkgs.writeShellScriptBin "faceTracking" ''
    aitrack &disown
    opentrack &disown
  '';
in {
  options = {
    programs.faceTracking.enable = lib.mkEnableOption "Enable AI face tracking";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        pkgs.aitrack
        pkgs.opentrack
        faceTracking
      ];
    };
  };
}
