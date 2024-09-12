{ config, lib, pkgs, username, ... }:
let cfg = config.roles.desktop;
in {
  options.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    modules.programs = { zen-browser.enable = true; };
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
        easyeffects
        fastfetch
        file
        file-roller
        google-chrome
        jellyfin-media-player
        lampray
        mousai
        (nerdfonts.override {
          fonts = [ "CascadiaCode" "CascadiaMono" "FiraCode" "FiraMono" ];
        })
        nemo
        nitch
        nixd
        nix-index
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
        tldr
        vlc
        # mikrotik router mgmt app .
        (winbox.override { wine = wineWowPackages.waylandFull; })
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
