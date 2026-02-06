{ ... }:
{
  flake.nixosModules.btrfs =
    { ... }:
    {
      services = {
        fstrim = {
          enable = true;
          interval = "weekly";
        };

        btrfs.autoScrub = {
          enable = true;
          interval = "monthly";
          fileSystems = [ "/" ];
        };
      };
    };
}
