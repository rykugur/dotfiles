{
  inputs,
  pkgs,
  ...
}: let
  faceTracking = pkgs.writeShellScriptBin "faceTracking" ''
    aitrack &disown
    opentrack &disown
  '';
in {
  home.packages = [
    pkgs.aitrack
    pkgs.opentrack
    faceTracking
  ];
}
