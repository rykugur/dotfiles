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
        file
        file-roller
        google-chrome
        lampray
        mousai
        # neofetch
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
        # solaar
        spotify
        vlc
        xdg-utils
        xfce.thunar
        zenity

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

          defaultApplications = { "inode/directory" = [ "nemo.desktop" ]; };
        };
      };
    };
  };
}
