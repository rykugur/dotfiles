{ lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    ./_ssh-access.nix
  ];

  networking.hostName = "vasher";
  networking.useDHCP = lib.mkForce true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };

  system.stateVersion = "24.11";
}
