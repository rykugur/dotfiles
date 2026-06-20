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
