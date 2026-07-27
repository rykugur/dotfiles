# modules/misc/dusty-nfs.nix
#
# NFSv4 share from truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs mounted at
# /mnt/dusty-nfs.
# Uses systemd automount: `noauto` + `x-systemd.automount` so nothing happens at
# boot — the mount is established on first access and torn down after the
# idle-timeout. Keeps the system responsive when the server is unreachable.
#
# Darwin (taln) is supported via autofs: `flake.modules.darwin.dusty-nfs`
# writes a direct map, splices /etc/auto_master in a postActivation script, and
# symlinks ~/Documents/dusty-nfs to a neutral data-volume mountpoint. On-demand
# autofs keeps taln responsive when off-LAN (truenas.local.ryk.sh won't resolve).
{ ... }:
{
  flake.modules.nixos.dusty-nfs =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nfs-utils ];

      fileSystems."/mnt/dusty-nfs" = {
        device = "truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs";
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

  flake.modules.darwin.dusty-nfs =
    { username, ... }:
    let
      mountPoint = "/System/Volumes/Data/mnt/dusty-nfs";
    in
    {
      # Direct autofs map. soft+timeo mirror jezrien so I/O errors instead of
      # hanging when truenas is unreachable (taln is often off-LAN). resvport
      # because macOS clients otherwise use a high source port some TrueNAS
      # exports reject; harmless when not required.
      environment.etc."auto_dusty_nfs".text = ''
        ${mountPoint} -fstype=nfs,vers=4,soft,timeo=50,resvport,rw truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs
      '';

      system.activationScripts.postActivation.text = ''
        # neutral mountpoint parent lives on the writable data volume
        /bin/mkdir -p "$(/usr/bin/dirname ${mountPoint})"

        # idempotently register the direct map with macOS's auto_master
        if ! /usr/bin/grep -q '/etc/auto_dusty_nfs' /etc/auto_master; then
          printf '/-\t\t\t/etc/auto_dusty_nfs\n' >> /etc/auto_master
        fi

        /usr/sbin/automount -vc || true
      '';

      # ~/Documents/dusty-nfs -> mountpoint, declarative via home-manager
      home-manager.users.${username} =
        { config, ... }:
        {
          home.file."Documents/dusty-nfs".source =
            config.lib.file.mkOutOfStoreSymlink mountPoint;
        };
    };
}
