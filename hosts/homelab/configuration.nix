{ config, inputs, modulesPath, pkgs, hostname, username, ... }: {
  imports = [
    inputs.sops-nix.nixosModules.default
    inputs.disko.nixosModules.disko

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    firewall.enable = false;
    hostName = hostname;
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules =
    [ "L+ /usr/local/bin - - - - /run/current-system/sw/bin/" ];
  virtualisation.docker.logDriver = "json-file";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      token = { };
      private_age_key = {
        path = "/var/lib/sops-nix/key.txt";
        mode = "0440";
      };
    };
  };

  services = {
    k3s = {
      enable = true;
      role = "server";
      tokenFile = config.sops.secrets.token;
      extraFlags = toString ([
        ''--write-kubeconfig-mode "0644"''
        "--cluster-init"
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
      ] ++ (if hostname == "homelab-0" then
        [ ]
      else
        [ "--server https://homelab-0:6443" ]));
      clusterInit = (hostname == "homelab-0");
    };

    openssh.enable = true;
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${hostname}";
  };

  environment.systemPackages = with pkgs; [
    neovim
    k3s
    cifs-utils
    nfs-utils
    git
  ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ tree ];
    hashedPassword =
      "$6$0hzZMZR5v61jpeBv$I67bZJrFsmhqCKV/FgR970rlZLdlFmkL6ikgE/ktDM98XMnBwjyIP3dEVPIuusqm/W9Pglja70GQR3AwcwuLf0";
    openssh.authorizedKeys.keys = [
      # "personal"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
      # jezrien
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
    ];
  };

  system.stateVersion = "24.05";
}
