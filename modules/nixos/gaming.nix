{ pkgs, ... }: {
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    gamemode = {
      enable = true;
      settings = {
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
