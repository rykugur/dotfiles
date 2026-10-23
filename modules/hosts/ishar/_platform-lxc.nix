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
    manageNetwork = false;
    manageHostName = true;
  };

  # The stock `99-ethernet-default-dhcp` excludes veth, which is exactly what
  # an LXC gets, so DHCP needs a matching network of its own. The lease carries
  # the hostname, which is what publishes `ishar.local.ryk.sh` in LAN DNS.
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
    dhcpV4Config = {
      SendHostname = true;
      Hostname = config.networking.hostName;
    };
  };

  # networkd depends on this; the systemd module disables it for containers.
  systemd.additionalUpstreamSystemUnits = [ "systemd-udev-trigger.service" ];
}
