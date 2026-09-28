{ self, ... }:
{
  # System-level gaming bits (peripherals, kernel/udev). Paired with the
  # home-manager gaming group below — import both at their respective layers.
  flake.modules.nixos.gaming =
    { ... }:
    {
      imports = with self.modules.nixos; [
        virpil
      ];
    };

  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        depotdownloader
        discord
        lutris
        moonlight
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
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
}
