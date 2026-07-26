{ lib, modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  networking.hostName = "vasher";
  networking.useDHCP = lib.mkForce true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  ];

  system.stateVersion = "24.11";
}
