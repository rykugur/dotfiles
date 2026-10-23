{ pkgs, ... }:
let
  username = "dusty";
  sshKeys = import ../../misc/_dusty-ssh-keys.nix;
in
{
  networking = {
    hostName = "ashyn";
    # No explicit nameservers: the Default VLAN's DHCP already hands out
    # resolvers, and pinning AdGuard here would only diverge from the lease.
    firewall.enable = true;
  };

  # 4 cores / 15G, and comin builds whatever vasher hasn't already cached.
  # Two jobs of two cores leaves the hypervisor responsive while a guest runs.
  nix.settings = {
    trusted-users = [
      "root"
      username
    ];
    max-jobs = 2;
    cores = 2;
  };

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # This box has no IPMI and one NIC: if a comin generation breaks the bridge,
  # the only recovery is a keyboard. Root-by-key is the cheap middle rung for
  # everything short of that.
  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    jq
  ];

  system.stateVersion = "26.05";
}
