{ self, ... }:
{
  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        discord
        lutris
      ];

      home.packages = with pkgs; [
        steamcmd

        protonplus
        protonup-ng
        protonup-qt
        winetricks

        bottles
        dxvk
        gamescope
        heroic
        mangohud
        moonlight-qt
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
}
