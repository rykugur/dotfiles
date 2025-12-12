{ config, inputs, lib, username, ... }:
let cfg = config.rhx.starcitizen;
in {
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  options.rhx.starcitizen.enable =
    lib.mkEnableOption "Enable starcitizen module";

  config = lib.mkIf cfg.enable {
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

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
