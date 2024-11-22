{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.face-tracking;
  # TODO: re-write this/consider removing
  faceTracking = pkgs.writeShellScriptBin "faceTracking" ''
    aitrack &disown
    opentrack &disown
  '';
in {
  options.rhx.face-tracking = {
    enable = lib.mkEnableOption "Enable face-tracking home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.aitrack pkgs.opentrack faceTracking ];
  };
}
