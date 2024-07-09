{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.roles.desktop;
in {
  options.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    modules.wm.gtk.enable = true;

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        baobab
        bat
        bottom
        cinnamon.nemo
        easyeffects
        file
        gnome.seahorse
        gnome.zenity
        google-chrome
        lampray
        mousai
        neofetch
        nitch
        nvtopPackages.full
        obsidian
        opera
        pavucontrol
        playerctl
        radeontop
        solaar
        spotify
        vlc
        xdg-utils
        xfce.thunar

        p7zip
        unzip
        xz
        zip

        dnsutils
        duf
        eza
        fzf
        grc
        jq
        ldns
        lm_sensors
        nmap
        pciutils
        psmisc
        ripgrep
        silver-searcher
        speedtest-cli
        tree
        usbutils
        wget
        zoxide

        btop
        iotop
        iftop
      ];
    };
  };
}
