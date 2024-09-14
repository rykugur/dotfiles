{ config, lib, pkgs, username, ... }:
let cfg = config.roles.server;
in {
  options.roles.server.enable = lib.mkEnableOption "Enable server role";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      file
      nixd
      nix-index
      sshfs
      tigervnc

      p7zip
      unzip
      xz
      zip

      dnsutils
      jq
      ldns
      lm_sensors
      nmap
      pciutils
      psmisc
      ripgrep
      silver-searcher
      tree
      usbutils
      wget
    ];

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        bat
        duf
        eza
        fzf
        speedtest-cli
        zoxide

        btop
        iotop
        iftop
      ];
    };
  };
}
