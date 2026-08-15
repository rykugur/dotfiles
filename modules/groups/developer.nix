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

        # terminal
        helix
        ghostty
        kitty
        bat
        carapace
        direnv
        starship
        zellij
        zoxide
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
          duf
          dust
          dysk
          fzf
          gdu
          glow
          ldns
          lsof
          jq
          nmap
          p7zip
          ripgrep
          speedtest-cli
          tree
          unzip
          wget
          xz
          zip
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
