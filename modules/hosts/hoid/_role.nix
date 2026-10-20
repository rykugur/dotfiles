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
  # root-only `lxc.*` keys a CT recreate loses) for no reach we do not have.
  ryk.ompHost = {
    enable = true;
    # ompweb drives omp over RPC on this box and reads its sessions straight
    # from disk, so the chat UI involves no relay at all. Caddy publishes it
    # on port 80; ompweb itself stays on loopback because it has no TLS.
    web = {
      enable = true;
      name = "hoid";
      passwordHashFile = config.sops.secrets.ompweb_password_hash.path;
    };
    # The dtach session exists only to host a Collab room, which is relayed
    # through my.omp.sh. Off: the web UI covers the same job on the LAN.
    session.enable = false;
    ttyd.enable = false;
    linkService.enable = false;
    broker = {
      enable = true;
      # Bearer-token authenticated; jezrien and taln reach it over the LAN.
      bind = "0.0.0.0:8765";
    };
    openFirewall = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."http://hoid.local.ryk.sh".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.ryk.ompHost.web.port}
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "24.11";
}
