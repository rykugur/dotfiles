{ config, inputs, lib, ... }:
let cfg = config.rhx.starcitizen;
in {
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  options.rhx.starcitizen.enable =
    lib.mkEnableOption "Enable starcitizen nixOS module";

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters =
        [ "https://nix-gaming.cachix.org" "https://nix-citizen.cachix.org" ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      ];
    };

    services.udev = {
      enable = true;
      extraRules = ''
        # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
        KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
      '';

    };

    nix-citizen.starCitizen = {
      enable = true;
      # Additional commands before the game starts
      preCommands = ''
        export PULSE_LATENCY_MSEC=40
        export DXVK_HUD=compiler;
        export MANGO_HUD=1;
      '';

      patchXwayland = true;

      umu.enable = true;
      disableEAC = false;
    };
  };
}
