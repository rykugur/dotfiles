{ self, ... }:
{
  flake.modules.homeManager.developer =
    { lib, pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        # dev
        atuin
        devenv
        git
        yaak
        zed-editor

        # terminal
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

      home.packages =
        with pkgs;
        [
          # dev
          ### js/ts/node
          bun
          nodejs
          ### misc
          just
          prettierd
          stylua
          vscode
          bruno
          insomnia

          # terminal
          cmatrix
          dnsutils
          dysk
          fzf
          jq
          glow
          ldns
          lsof
          nmap
          p7zip
          silver-searcher
          speedtest-cli
          tree
          unzip
          wget
          xz
          zip
          duf
          dust
          gdu
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          warp-terminal
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          iftop
          iotop
          lm_sensors
          pciutils
          psmisc
          usbutils
        ];
    };
}
