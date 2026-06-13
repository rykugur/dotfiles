# modules/misc/dusty-nfs.nix
#
# NFSv4 share from truenas.local.ryk.sh:/mnt/dusty-nfs mounted at /mnt/dusty-nfs.
# Uses systemd automount: `noauto` + `x-systemd.automount` so nothing happens at
# boot — the mount is established on first access and torn down after the
# idle-timeout. Keeps the system responsive when the server is unreachable.
#
# Darwin (taln) intentionally not registered. taln is frequently off-LAN where
# *.local.ryk.sh doesn't resolve; nix-darwin also requires an imperative
# activation script to splice /etc/auto_master. Revisit if taln needs it.
{ ... }:
{
  flake.modules.nixos.dusty-nfs =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nfs-utils ];

      fileSystems."/mnt/dusty-nfs" = {
        device = "truenas.local.ryk.sh:/mnt/dusty-nfs";
        fsType = "nfs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=600"
          "x-systemd.mount-timeout=10s"
          "x-systemd.device-timeout=10s"
          "nfsvers=4"
          "soft"
          "timeo=50"
        ];
      };
    };
}
