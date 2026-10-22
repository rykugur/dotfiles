{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen =
    { config, pkgs, ... }:
    let
      username = config.ryk.username;
    in
    {
      imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

      security.pam.loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "16777216";
        }
      ];

      nix.settings = {
        substituters = [
          "https://nix-citizen.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };

      programs.rsi-launcher = {
        enable = true;
        enableNTsync = false; # Jezrien imports the standalone ntsync module.

        # Launch OpenTrack alongside RSI Launcher in the same Wine environment.
        preCommands = ''
          ${pkgs.opentrack}/bin/opentrack &
          scOpentrackPid=$!
          export MESA_VK_WSI_PRESENT_MODE=mailbox
          export DXVK_HUD=compiler
          export MANGO_HUD=1
          export MANGOHUD=1
          export WINE_HIDE_NVIDIA_GPU=1
          export PROTON_ENABLE_WAYLAND=1
          export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winewayland.drv=n,b"
        '';
        postCommands = ''
          kill "$scOpentrackPid" 2>/dev/null || true
        '';

        patchXwayland = true;
        enforceWaylandDrv = true;
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen ];
    };

  flake.modules.homeManager.starcitizen =
    { pkgs, ... }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      lug-helper = inputs.nix-citizen.packages.${sys}.lug-helper;
      wineAstralPkg = inputs.nix-citizen.packages.${sys}.wine-astral;
    in
    {
      home.packages = with pkgs; [
        opentrack
        lug-helper
      ];

      # lazy-mode - for opentrack
      home.file.".wine-astral".source = wineAstralPkg;
    };
}
