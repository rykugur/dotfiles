{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  boot = {
    isContainer = true;
    loader.grub.enable = lib.mkForce false;
    loader.systemd-boot.enable = lib.mkForce false;
  };

  fileSystems = lib.mkForce { };

  proxmoxLXC = {
    privileged = false;
    # Proxmox hands the container its address; systemd-networkd accepts it.
    manageNetwork = false;
    # The flake owns the identity, not the Proxmox CT config.
    manageHostName = true;
  };

  # The stock `99-ethernet-default-dhcp` excludes veth, which is exactly what
  # an LXC gets, so DHCP needs a matching network of its own.
  systemd.network.networks."99-lxc-veth-dhcp" = {
    matchConfig = {
      Type = "ether";
      Kind = "veth";
      Name = [
        "en*"
        "eth*"
      ];
    };
    DHCP = "yes";
    networkConfig.IPv6PrivacyExtensions = "kernel";
    # UniFi registers `<name>.local.ryk.sh` from DHCP option 12, and AdGuard
    # forwards the zone to the router, so the lease is what publishes this
    # host in LAN DNS. Send it explicitly rather than relying on whatever
    # gethostname() returns while networkd is starting.
    dhcpV4Config = {
      SendHostname = true;
      Hostname = config.networking.hostName;
    };
  };

  # networkd depends on this; the systemd module disables it for containers.
  systemd.additionalUpstreamSystemUnits = [ "systemd-udev-trigger.service" ];
}
