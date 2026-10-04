# modules/misc/dusty-nfs.nix
#
# NFSv4 share from truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs mounted at
# /mnt/dusty-nfs.
# Uses systemd automount: `noauto` + `x-systemd.automount` so nothing happens at
# boot — the mount is established on first access and torn down after the
# idle-timeout. Keeps the system responsive when the server is unreachable.
#
# Darwin (taln) is supported via autofs: `flake.modules.darwin.dusty-nfs`
# writes a direct map and splices /etc/auto_master. The splice itself also
# runs from a LaunchDaemon (RunAtLoad + hourly), not just activation:
# macOS has been observed to strip the appended line from /etc/auto_master
# on its own (independent of reboots/updates), so relying solely on
# `darwin-rebuild switch` to re-apply it leaves the mount dead until the
# next manual rebuild. `extraActivation` still runs the same splice so a
# rebuild fixes it immediately without waiting for the daemon; it runs
# before homebrew/mas/fonts, all of which can abort the whole `set -e`
# activation script on failure. Then symlinks ~/Documents/dusty-nfs to a
# neutral data-volume mountpoint. On-demand autofs keeps taln responsive
# when off-LAN (truenas.local.ryk.sh won't resolve).
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
    { lib, username, ... }:
    let
      mountPoint = "/System/Volumes/Data/mnt/dusty-nfs";
      syncAutoMaster = ''
        /bin/mkdir -p "$(/usr/bin/dirname ${mountPoint})"

        # idempotently register the direct map with macOS's auto_master;
        # macOS has been observed to strip this line on its own, so this
        # must be safe to re-run, not just run once at activation time.
        if ! /usr/bin/grep -q '/etc/auto_dusty_nfs' /etc/auto_master; then
          printf '/-\t\t\t/etc/auto_dusty_nfs\n' >> /etc/auto_master
        fi

        /usr/sbin/automount -vc || true
      '';
    in
    {
      # Direct autofs map. soft+timeo mirror jezrien so I/O errors instead of
      # hanging when truenas is unreachable (taln is often off-LAN). resvport
      # because macOS clients otherwise use a high source port some TrueNAS
      # exports reject; harmless when not required.
      environment.etc."auto_dusty_nfs".text = ''
        ${mountPoint} -fstype=nfs,vers=4,soft,timeo=50,resvport,rw truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs
      '';

      # extraActivation runs early in nix-darwin's fixed activation pipeline —
      # before groups/users/etc/homebrew/postActivation — so this splice can't
      # be skipped by an unrelated failure later in the script (the whole
      # thing runs under `set -e`; e.g. a flaky `brew bundle` used to abort
      # before reaching this when it lived in postActivation).
      system.activationScripts.extraActivation.text = lib.mkAfter syncAutoMaster;

      # Belt-and-suspenders: macOS has been observed to strip the splice
      # from /etc/auto_master without any reboot or rebuild, so a daemon
      # re-applies it at boot and hourly rather than relying solely on the
      # next manual `darwin-rebuild switch`.
      launchd.daemons.dusty-nfs-automaster = {
        script = syncAutoMaster;
        serviceConfig = {
          RunAtLoad = true;
          StartInterval = 3600;
          StandardOutPath = "/var/log/dusty-nfs-automaster.log";
          StandardErrorPath = "/var/log/dusty-nfs-automaster.log";
        };
      };

      # ~/Documents/dusty-nfs -> mountpoint, declarative via home-manager
      home-manager.users.${username} =
        { config, ... }:
        {
          home.file."Documents/dusty-nfs".source =
            config.lib.file.mkOutOfStoreSymlink mountPoint;
        };
    };
}
