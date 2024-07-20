{ config, lib, pkgs, username, ... }:
let cfg = config.roles.desktop;
in {
  options.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    modules.wm.gtk.enable = true;

    fonts.packages = with pkgs;
      [
        (nerdfonts.override {
          fonts = [ "CascadiaCode" "CascadiaMono" "FiraCode" "FiraMono" ];
        })
      ];

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        baobab
        bat
        bottom
        cinnamon.nemo
        easyeffects
        fastfetch
        file
        file-roller
        google-chrome
        lampray
        mousai
        (nerdfonts.override {
          fonts = [ "CascadiaCode" "CascadiaMono" "FiraCode" "FiraMono" ];
        })
        nitch
        nvtopPackages.full
        obsidian
        opera
        pavucontrol
        playerctl
        radeontop
        seahorse
        solaar
        spotify
        sshfs
        tigervnc
        vlc
        winbox # mikrotik router mgmt app
        xdg-utils
        xfce.thunar
        zenity

        feh
        xfce.ristretto

        wofi
        wofi-emoji

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

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "image/png" = [ "feh.desktop" "org.xfce.ristretto.desktop" ];
            "image/jpg" = [ "feh.desktop" "org.xfce.ristretto.desktop" ];
            "image/jpeg" = [ "feh.desktop" "org.xfce.ristretto.desktop" ];
            "image/webp" = [ "feh.desktop" "org.xfce.ristretto.desktop" ];
            "inode/directory" = [ "thunar.desktop" ];
          };
        };
      };
    };
  };
}
