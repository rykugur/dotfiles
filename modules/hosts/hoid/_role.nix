{
  config,
  inputs,
  pkgs,
  ...
}:
let
  username = config.ryk.username;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

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

  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    fd
    file
    jq
    lsof
    pve-provision
    ripgrep
    tree
    unzip
    wget
  ];

  # The age identity is installed by `pve-provision --age-key-sops` while the
  # container is being provisioned, so secrets exist before the first switch.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      # Outbound key for *.local.ryk.sh and GitHub; public half is
      # ssh_id_ed25519.pub next to this file.
      ssh_private_key = {
        owner = username;
        path = "/home/${username}/.ssh/id_ed25519";
        mode = "0400";
      };
      ompweb_password_hash = { };
      # Bearer token the Collab link dispenser requires once Caddy exposes
      # it on the LAN (ryk.ompHost.linkService.tokenFile below).
      collab_link_token = { };
      # Read by Caddy for the ACME DNS-01 challenge; same token the cluster's
      # cert-manager uses.
      cloudflare_api_token = { };
    };
  };

  # Server side only. The shared `ssh` NixOS module additionally pulls in the
  # Home Manager sops layer, which this host does not run; the outbound key is
  # placed directly by `sops.secrets.ssh_private_key` above.
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

  # No Tailscale here. The homelab router already advertises 10.3.10.0/24 to
  # the tailnet, so a second node would add a /dev/net/tun requirement (two
  # root-only `lxc.*` keys a CT recreate loses) for reach the tailnet already
  # has through that route.
  ryk.ompHost = {
    enable = true;
    # ompweb drives omp over RPC on this box and reads its sessions straight
    # from disk, so the chat UI involves no relay at all.
    web = {
      enable = true;
      name = "hoid";
      passwordHashFile = config.sops.secrets.ompweb_password_hash.path;
    };
    # The dtach session exists to host a Collab room and the self-hosted
    # relay below carries it on the LAN/tailnet instead of my.omp.sh, so
    # another omp instance can join and prompt this agent without a
    # third-party hop. ompweb still covers the human/browser case.
    session.enable = true;
    ttyd.enable = false;
    linkService = {
      enable = true;
      tokenFile = config.sops.secrets.collab_link_token.path;
    };
    collab.relay.enable = true;
    broker = {
      enable = true;
      # Loopback: Caddy publishes it on 8765 with TLS. The bearer token is
      # the whole vault, so it should not cross the LAN in clear.
      bind = "127.0.0.1:8766";
    };
    proxy = {
      enable = true;
      hostName = "hoid.local.ryk.sh";
      tls.environmentFile = config.sops.templates."caddy-cloudflare.env".path;
    };
    openFirewall = true;
  };

  sops.templates."caddy-cloudflare.env" = {
    content = "CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}";
    owner = "caddy";
  };

  system.stateVersion = "24.11";
}
