{ lib, modulesPath, ... }:
{
  # Minimal first-boot system for the Proxmox CT template. It comes up on the
  # network with SSH; comin (added on top in `_image.nix`) pulls the real
  # `ishar` closure from master on its first poll.
  #
  # `lxc-container.nix`, not `proxmox-lxc.nix`: see hoid/_seed.nix for why
  # (register-nix-paths, systemd-udev-trigger, veth DHCP).
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ./_ssh.nix
  ];

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking = {
    hostName = "ishar";
    useDHCP = lib.mkForce true;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  services.openssh.startWhenNeeded = lib.mkForce false;

  system.stateVersion = "26.05";
}
