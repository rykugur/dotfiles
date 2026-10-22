{
  inputs,
  pkgs,
  ...
}:
let
  username = "dusty";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./_ssh.nix
  ];

  networking = {
    hostName = "ishar";
    # AdGuard, which is authoritative for the `local.ryk.sh` zone.
    nameservers = [
      "10.3.9.5"
      "10.3.9.6"
    ];
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
    # comin builds this host's closure locally; two jobs fits the CT's RAM.
    max-jobs = 2;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # personal
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
      # jezrien
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
      # taln
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKORtO51gYjGRuP3pP/paOe8NcBfQvrcZLSSwc4bqpT"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    git
    jq
  ];

  users.motd = "ishar — comin pilot, deployed from git. Do not nixos-rebuild.\n";

  system.stateVersion = "26.05";
}
