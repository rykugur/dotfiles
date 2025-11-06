{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.roles.terminal;
in {
  options.rhx.roles.terminal.enable = lib.mkEnableOption "Enable terminal role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = { };

    # home-manager config
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        cmatrix
        dnsutils
        duf
        dysk
        fzf
        jq
        iftop
        iotop
        glow
        ldns
        lsof
        lm_sensors
        ncdu
        nmap
        pciutils
        p7zip
        psmisc
        silver-searcher
        speedtest-cli
        tree
        unzip
        usbutils
        wget
        xz
        zip

      ];

      rhx = {
        ghostty.enable = true;
        kitty.enable = true;

        bat.enable = true;
        carapace.enable = true;
        direnv.enable = true;
        nushell.enable = true;
        starship.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zoxide.enable = true;

        helix.enable = true;
      };
    };
  };
}
