# Incus is the part under test: it replaces what PVE actually gives roshar —
# system containers, full VMs, a web UI, and an API that OpenTofu can drive —
# from nixpkgs proper rather than from an experimental third-party flake.
{ ... }:
{
  virtualisation.incus = {
    enable = true;
    ui.enable = true;

    # Default is already true; stated because it is the property that makes
    # comin safe here. A pull deploy restarts incus.service, and without this
    # every guest would be killed by a routine host switch.
    softDaemonRestart = true;

    # Re-applied by `incus-preseed.service` on every incus start, not just
    # the first. Measured on 2026-10-23: a changed preseed does update an
    # already initialised daemon (profiles and config are patched in place),
    # but it never prunes — an entity removed from this attrset, or a key
    # set back to "", stays on the host until deleted by hand.
    preseed = {
      config."core.https_address" = "[::]:8443";

      storage_pools = [
        {
          name = "local";
          driver = "btrfs";
          config.source = "/var/lib/incus/storage-pools/local";
        }
      ];

      profiles = [
        {
          name = "default";
          devices = {
            root = {
              type = "disk";
              path = "/";
              pool = "local";
            };
            # Bridged onto the host's only NIC, so guests are LAN peers with
            # their own DHCP leases, like guests behind roshar's vmbr0.
            eth0 = {
              type = "nic";
              name = "eth0";
              nictype = "bridged";
              parent = "br0";
            };
          };
        }
      ];
    };
  };

  # The guests themselves. `incus-instances.service` reconciles these on every
  # activation, so a push comin deploys is what changes a VM — no `tofu apply`
  # from a workstation, no API credential.
  #
  # amp: the CubeCoders AMP panel. Debian because AMP ships .deb packages and
  # installs its own systemd units; nothing about it is Nix-able, so the
  # declarative boundary is the VM and its disk, with `/home/amp/.ampdata` as
  # the data to back up.
  ryk.incus.instances.amp = {
    image = "images:debian/12";
    virtualMachine = true;
    config = {
      "limits.cpu" = "3";
      "limits.memory" = "6GiB";
      # The Debian VM image is unsigned, so OVMF's secureboot rejects it.
      "security.secureboot" = "false";
      # Start with the host rather than relying on Incus restoring whatever
      # was running when it last stopped.
      "boot.autostart" = "true";
    };
    devices.root = {
      type = "disk";
      path = "/";
      pool = "local";
      size = "32GiB";
    };
  };

  # A second VM created by comin after impermanence was already live.
  # Keep it declared to verify guest persistence across later host updates.
  ryk.incus.instances.ashyn-probe = {
    image = "images:alpine/edge";
    virtualMachine = true;
    config = {
      "limits.cpu" = "1";
      "limits.memory" = "1GiB";
      "security.secureboot" = "false";
      "boot.autostart" = "true";
    };
    devices.root = {
      type = "disk";
      path = "/";
      pool = "local";
      # Incus initially allocates 10GiB; PATCH cannot shrink block volumes.
      size = "16GiB";
    };
  };

  # Incus asserts on iptables; it manages its own nft chains.
  networking.nftables.enable = true;

  # Incus HTTPS API and web UI.
  networking.firewall.allowedTCPPorts = [ 8443 ];
}
