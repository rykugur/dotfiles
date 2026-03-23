{
  config,
  lib,
  pkgs,
  username,
  outputs,
  ...
}:
let
  cfg = config.ryk.roles.terminal;
in
{
  options.ryk.roles.terminal.enable = lib.mkEnableOption "Enable terminal role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # ryk = { };

    # home-manager config
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        cmatrix
        dnsutils
        dysk
        fzf
        jq
        iftop
        iotop
        glow
        ldns
        lsof
        lm_sensors
        nmap
        pciutils
        p7zip
        psmisc
        silver-searcher
        speedtest-cli
        tree
        unzip
        usbutils
        warp-terminal
        wget
        xz
        zip

        duf
        dust
        gdu
      ];

      imports = with outputs.modules.homeManager; [
        ghostty
        kitty
        bat
        carapace
        direnv
        starship
        yazi
        zellij
        zoxide
        helix
      ];
    };
  };
}
