# Shared platform for QEMU guests on Proxmox: UEFI boot, virtio disks and NIC,
# the guest agent, and a DHCP lease that publishes the host in LAN DNS.
# Partitioning is per host, in that host's `_disko.nix`.
{ inputs, ... }:
{
  flake.modules.nixos.pve-vm =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        inputs.disko.nixosModules.disko
      ];

      # Lets Proxmox report the guest's address and shut it down cleanly.
      services.qemuGuest.enable = true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_scsi"
        "virtio_blk"
        "virtio_net"
        "sr_mod"
      ];

      services.openssh.enable = true;

      # Same DNS mechanism as the LXC platform: UniFi registers
      # `<name>.local.ryk.sh` from DHCP option 12, so the lease has to carry the
      # hostname explicitly rather than whatever gethostname() returns while
      # networkd is starting.
      networking.useNetworkd = true;
      networking.useDHCP = lib.mkForce false;
      systemd.network.networks."10-pve-dhcp" = {
        matchConfig.Type = "ether";
        DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = "kernel";
        dhcpV4Config = {
          SendHostname = true;
          Hostname = config.networking.hostName;
        };
      };
    };
}
