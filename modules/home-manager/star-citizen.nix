{ inputs, pkgs, ... }:
let
  scFaceTracking = pkgs.writeShellScriptBin "scFaceTracking" ''
    aitrack &disown
    opentrack &disown
  '';
in
{
  home.packages = [
    pkgs.aitrack
    pkgs.opentrack
    scFaceTracking
  ];

}
