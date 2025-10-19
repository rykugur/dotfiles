{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.rhx.starcitizen;
in {
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  options.rhx.starcitizen.enable =
    lib.mkEnableOption "Enable starcitizen nixOS module";

  config = lib.mkIf cfg.enable {
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
        export DXVK_HUD=compiler
        export MANGO_HUD=1
      '';

      # package = inputs.nix-citizen.packages.${pkgs.system}.star-citizen-umu;

      patchXwayland = true;

      umu.enable = true;
      disableEAC = false;
    };

    home-manager.users.${username} = { rhx.starcitizen.enable = true; };
  };
}
