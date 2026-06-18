{ ... }:
{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;

        extraPackages = with pkgs; [
          gamemode
          # Elite Dangerous launcher; set ED's Steam launch options to:
          #   MinEdLauncher /steam /edo %command%
          min-ed-launcher
        ];
        extraCompatPackages = [ pkgs.proton-ge-bin ];

        protontricks.enable = true;
      };
    };
}
