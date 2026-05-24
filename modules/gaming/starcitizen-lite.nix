{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen-lite =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.ryk.username;
    in
    {
      # LUG prereqs — https://wiki.starcitizen-lug.org/Alternative-Installations
      # Values match nix-citizen's (which exceed the LUG floor of 1048576 / 524288).
      boot.kernel.sysctl = {
        "vm.max_map_count" = lib.mkOverride 999 16777216;
        "fs.file-max" = lib.mkOverride 999 524288;
      };

      security.pam.loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "16777216";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "16777216";
        }
      ];

      # Kernel modules nix-citizen sets up for SC's audio/video pipeline.
      boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      boot.kernelModules =
        [ "snd-aloop" ]
        ++ lib.optional (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14") "ntsync";

      services.udev = {
        enable = true;
        # lug-helper bundles joystick/HOTAS udev rules. services.udev.packages
        # pulls only /etc/udev/rules.d from the package — the GUI binary stays
        # out of the system closure unless explicitly added to systemPackages.
        packages = [ pkgs.lug-helper ];
        extraRules = ''
          # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
          KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
        '';
      };

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

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen-lite ];
    };

  flake.modules.homeManager.starcitizen-lite =
    { pkgs, ... }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      gameglass = inputs.nix-citizen.packages.${sys}.gameglass;
      wineAstralPkg = inputs.nix-citizen.packages.${sys}.wine-astral;
    in
    {
      home.packages = with pkgs; [
        opentrack-StarCitizen
        gameglass
      ];

      # opentrack needs a wine prefix on disk to talk to the SC wine instance.
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
