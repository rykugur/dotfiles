{ ... }:
{
  flake.modules.homeManager.discord =
    { pkgs, lib, ... }:
    let
      mkDiscordWrapper = name:
        lib.hiPrio (pkgs.writeShellScriptBin name ''
          exec ${lib.getExe' pkgs.discord name} \
            --ozone-platform=wayland \
            --enable-features=WaylandWindowDrag,WebRTCPipeWireCapturer \
            "$@"
        '');
    in
    {
      home.packages = [
        pkgs.discord
        (mkDiscordWrapper "Discord")
        (mkDiscordWrapper "discord")
        pkgs.betterdiscordctl
      ];
    };
}
