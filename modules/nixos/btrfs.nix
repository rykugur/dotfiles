{ ... }:
{
  flake.modules.nixos.btrfs =
    { pkgs, ... }:
    {
      services = {
        fstrim = {
          enable = true;
          interval = "weekly";
        };

        btrfs.autoScrub = {
          enable = true;
          # Weekly rather than monthly. A single missed monthly run leaves the
          # array unverified for two months, which is what happened on
          # 2026-10-01. A full scrub of this filesystem takes ~5 minutes at
          # Nice=19 / idle I/O priority, so the extra frequency costs nothing.
          interval = "weekly";
          fileSystems = [ "/" ];
        };
      };

      # Upstream leaves a missed or cancelled scrub completely silent. Notify on
      # both units: the timer can fail to queue its job (on 2026-10-01 it failed
      # with result 'resources' because a suspend transaction was already
      # pending), and the service itself can be cancelled mid-run.
      systemd.timers."btrfs-scrub@" = {
        onFailure = [ "btrfs-scrub-failed@%i.service" ];
        # Persistent=true makes a missed scrub fire the instant the machine
        # boots or resumes, competing with session startup. Spread it out.
        timerConfig.RandomizedDelaySec = "20m";
      };

      systemd.services."btrfs-scrub@".onFailure = [ "btrfs-scrub-failed@%i.service" ];

      # %f is the instance name unescaped back into a path, so for
      # btrfs-scrub-failed@-.service it renders as "/".
      systemd.services."btrfs-scrub-failed@" = {
        description = "Report a failed btrfs scrub on %f";
        serviceConfig = {
          Type = "oneshot";
          # Only jezrien imports this module, and the notification has to reach
          # Dusty's graphical session bus.
          User = "dusty";
          # Leading '-' so a missing graphical session does not fail the unit;
          # the journal line above the notification is the durable record.
          ExecStart = "-${
            pkgs.writeShellScript "btrfs-scrub-failed-notify" ''
              mountpoint="$1"
              unit="$2"
              echo "btrfs scrub on $mountpoint failed or was cancelled; see journalctl -u $unit"
              # Do not use the %U specifier here: in a system-manager unit it
              # resolves to the service manager's UID (0), not User=, so the bus
              # path came out as /run/user/0/bus. Derive it from the process,
              # which already runs as User= above.
              export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus"
              exec ${pkgs.libnotify}/bin/notify-send --urgency=critical --app-name=btrfs \
                "btrfs scrub failed" \
                "Scrub on $mountpoint did not complete. Check: journalctl -u $unit"
            ''
          } %f btrfs-scrub@%i";
        };
      };
    };
}
