{
  inputs,
  pkgs,
  ...
}:
let
  username = "dusty";
  sshKeys = import ./_ssh-keys.nix;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  networking = {
    hostName = "nale";
    # AdGuard, which is authoritative for the `local.ryk.sh` zone.
    nameservers = [
      "10.3.9.5"
      "10.3.9.6"
    ];
    firewall.enable = true;
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    trusted-users = [
      "root"
      username
    ];
    max-jobs = 2;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # Root stays reachable by key so a broken comin generation can be repaired
  # over SSH without the Proxmox console.
  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    jq
  ];

  system.stateVersion = "26.05";
}
