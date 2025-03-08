{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.head-tracking;
  launchScript = pkgs.writeShellScriptBin "launch-ai-track-and-opentrack" ''
    ${pkgs.aitrack}/bin/aitrack &
    ${pkgs.opentrack}/bin/opentrack &
  '';
in {
  options.rhx.head-tracking = {
    enable = lib.mkEnableOption "Enable head-tracking home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.aitrack
      pkgs.opentrack
      (pkgs.makeDesktopItem {
        name = "AITrackAndOpenTrack";
        exec = "${launchScript}/bin/launch-ai-track-and-opentrack";
        comment = "Launch AITrack and OpenTrack together";
        desktopName = "AITrack + OpenTrack";
        categories = [ "Utility" "Science" ];
        icon = builtins.fetchurl {
          url =
            "https://github.com/opentrack/opentrack/raw/opentrack-2023.3.0/gui/images/opentrack.png";
          sha256 = "0d114zk78f7nnrk89mz4gqn7yk3k71riikdn29w6sx99h57f6kgn";
        };
      })
    ];

    # xdg.desktopEntries = {
    #   name = "AITrackAndOpenTrack";
    #   exec = "launchScript}/bin/launch-ai-track-and-opentrack";
    #   icon = builtins.fetchurl {
    #     url =
    #       "https://github.com/opentrack/opentrack/raw/opentrack-2023.3.0/gui/images/opentrack.png";
    #     sha256 = "0d114zk78f7nnrk89mz4gqn7yk3k71riikdn29w6sx99h57f6kgn";
    #   };
    #   terminal = false;
    #   # type = "Application";
    # };
  };
}
