{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen =
    { config, ... }:
    let
      username = config.ryk.username;
    in
    {
      imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

      services.udev = {
        enable = true;
        extraRules = ''
          # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
          KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
        '';
      };

      nix.settings = {
        substituters = [ "https://nix-citizen.cachix.org" ];
        trusted-public-keys = [
          "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
        ];
      };

      programs.rsi-launcher = {
        enable = true;

        # Additional commands before the game starts
        preCommands = ''
          export MESA_VK_WSI_PRESENT_MODE=mailbox
          export DXVK_HUD=compiler
          export MANGO_HUD=1
          export MANGOHUD=1
          export WINE_HIDE_NVIDIA_GPU=1
          export PROTON_ENABLE_WAYLAND=1
          export WINEDLLOVERRIDES="winewayland.drv=n,b"
        '';

        patchXwayland = true;
        enforceWaylandDrv = true;
        # umu.enable = true;
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen ];
    };

  flake.modules.homeManager.starcitizen =
    { pkgs, ... }:
    let
      gameglass = inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.gameglass;
      wineAstralPkg = inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.wine-astral;
    in
    {
      home.packages = with pkgs; [
        opentrack-StarCitizen
        gameglass
      ];

      # lazy-mode - for opentrack
      home.file.".wine-astral".source = wineAstralPkg;

      xdg.desktopEntries.gameglass = {
        name = "GameGlass";
        icon = "gameglass";
        exec = "${gameglass}/bin/gameglass";
        terminal = false;
        type = "Application";
        categories = [
          "Game"
          "Utility"
        ];
      };
    };
}
