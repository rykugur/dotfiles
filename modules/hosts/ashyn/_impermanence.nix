# Only the host's root is rolled back. /home, /nix, and /var/lib/incus
# are independent Btrfs subvolumes; Incus's database and guest disks survive
# a rollback together. Keep the identity and comin state on /persist.
{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/comin"
      "/var/lib/nixos"
      "/var/log/journal"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
