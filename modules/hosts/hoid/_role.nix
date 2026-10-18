{
  config,
  pkgs,
  ...
}:
let
  username = config.ryk.username;
in
{
  networking = {
    hostName = "hoid";
    # AdGuard resolves *.local.ryk.sh; the Proxmox VLAN's DHCP nameserver does
    # not, so pin it rather than take whatever DHCP hands out.
    nameservers = [
      "10.3.9.5"
      "10.3.9.6"
    ];
    firewall.enable = true;
  };

  nix.settings = {
    trusted-users = [
      "root"
      username
    ];
    max-jobs = 2;
  };

  # Agent-facing tooling. Infrastructure clients (kubectl, proxmox API access)
  # land here once their credentials exist; see Arcanum's [[Hoid]] page.
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    fd
    file
    jq
    lsof
    ripgrep
    tree
    unzip
    wget
  ];

  # The shared `ssh` NixOS module also wires a sops-backed private key through
  # modules/hosts/hoid/secrets.yaml, which does not exist yet. Inline the
  # server side with the same operator keys instead.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
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

  # Reaches the LAN and the tailnet. `tailscale up` is a one-time manual step;
  # no auth key is baked into the closure.
  services.tailscale.enable = true;

  ryk.ompHost = {
    enable = true;
    broker.enable = true;
  };

  system.stateVersion = "24.11";
}
