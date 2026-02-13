{ inputs, self, withSystem, ... }:
{
  flake.nixosModules.star-citizen =
    { config, ... }:
    let
      username = config.meta.ryk.username;
    in
    {
      imports = [
        inputs.nix-citizen.nixosModules.StarCitizen
        # TODO: enable opentrack, maybe VR modules? Or make a star-citizen feature to do that?
      ];

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
          export DISPLAY=""
          export DXVK_HUD=compiler
          export MANGO_HUD=1
        '';

        patchXwayland = true;
        # umu.enable = true;
      };

      home-manager.users.${username}.imports = [ self.homeModules.star-citizen ];
    };

  flake.homeModules.star-citizen =
    { pkgs, ... }:
    let
      scPkgs = withSystem pkgs.stdenv.hostPlatform.system (
        { config, inputs', ... }:
        {
          opentrackSC = config.packages.opentrack-StarCitizen;
          gameglass = inputs'.nix-citizen.packages.gameglass;
          wineAstral = inputs'.nix-citizen.packages.wine-astral;
        }
      );
    in
    {
      home.packages = [
        scPkgs.opentrackSC
        scPkgs.gameglass
      ];

      # lazy-mode - for opentrack
      # TODO: this probably belongs in a feature/meta module
      home.file.".wine-astral".source = scPkgs.wineAstral;

      xdg.desktopEntries.gameglass = {
        name = "GameGlass";
        icon = "gameglass";
        exec = "${scPkgs.gameglass}/bin/gameglass";
        terminal = false;
        type = "Application";
        categories = [
          "Game"
          "Utility"
        ];
      };
    };
}
