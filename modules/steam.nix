{ ... }:
{
  flake.nixosModules.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;

        extraCompatPackages = [ pkgs.proton-ge-bin ];

        protontricks.enable = true;
      };
    };
}
