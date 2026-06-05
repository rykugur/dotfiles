{ ... }:
{
  flake.modules.homeManager.discord =
    { pkgs, lib, ... }:
    let
      mkDiscordWrapper = name:
        lib.hiPrio (pkgs.writeShellScriptBin name ''
          export NIXOS_OZONE_WL=1
          exec ${lib.getExe' pkgs.discord name} "$@"
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
