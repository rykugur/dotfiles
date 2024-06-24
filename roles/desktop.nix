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

      # gtk = {
      #   enable = true;
      #
      #   font.name = "FiraCode Nerd Font Mono 10";
      #
      #   theme = {
      #     name = "catppuccin-mocha-compact-blue-dark";
      #     package = pkgs.catppuccin-gtk.override {
      #       accents = [ "blue" ];
      #       size = "compact";
      #       tweaks = [ "rimless" ];
      #       variant = "mocha";
      #     };
      #   };
      #
      #   cursorTheme = {
      #     name = "Bibata-Modern-Ice";
      #     package = pkgs.bibata-cursors;
      #   };
      #
      #   iconTheme = {
      #     name = "Vimix-dark";
      #     package = pkgs.vimix-icon-theme;
      #   };
      #
      #   gtk3.extraConfig = {
      #     Settings = ''
      #       gtk-application-prefer-dark-theme=1
      #     '';
      #   };
      #
      #   gtk4.extraConfig = {
      #     Settings = ''
      #       gtk-application-prefer-dark-theme=1
      #     '';
      #   };
      # };
      # home.pointerCursor = {
      #   gtk.enable = true;
      #   name = "Bibata-Modern-Ice";
      #   package = pkgs.bibata-cursors;
      #   size = 16;
      # };

    };
  };
}
