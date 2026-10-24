# Bare-metal platform for ashyn. Module list from `nixos-generate-config` on
# the live installer (2026-10-23): NVMe root, Intel CPU, no out-of-band
# management — a broken boot or a broken bridge here needs a keyboard.
{
  config,
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.enable = true;

  # One onboard NIC, so it cannot both carry the host address and serve
  # guests: it is enslaved to br0 and br0 takes the DHCP lease. Guests
  # attached to br0 then get LAN addresses straight from UniFi, which is
  # exactly what roshar's vmbr0 does for its comin guests.
  #
  # br0 inherits the NIC's MAC so the lease (and any UniFi reservation) keeps
  # following the same address across the installer -> installed transition.
  networking.useNetworkd = true;
  networking.useDHCP = lib.mkForce false;

  systemd.network = {
    netdevs."10-br0".netdevConfig = {
      Name = "br0";
      Kind = "bridge";
      MACAddress = "6c:4b:90:01:66:69";
    };

    networks."10-uplink" = {
      matchConfig.Name = "enp0s31f6";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "enslaved";
    };

    # Same DNS mechanism the Proxmox guests use: UniFi registers
    # `<name>.local.ryk.sh` from DHCP option 12, so the lease has to carry the
    # hostname explicitly.
    networks."20-br0" = {
      matchConfig.Name = "br0";
      DHCP = "yes";
      networkConfig.IPv6PrivacyExtensions = "kernel";
      dhcpV4Config = {
        SendHostname = true;
        Hostname = config.networking.hostName;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # Incus loads br_netfilter, which would otherwise push every guest's bridged
  # packet through the host's firewall chains. Guests are LAN peers here, not
  # the host's traffic, so keep them out of the host firewall entirely — the
  # same separation PVE has.
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };
}
