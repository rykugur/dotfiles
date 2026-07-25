{ modulesPath, lib, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  boot.isContainer = true;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  fileSystems = lib.mkForce { };

  proxmoxLXC.manageNetwork = false;
  proxmoxLXC.manageHostName = true;
  proxmoxLXC.privileged = false;
}
