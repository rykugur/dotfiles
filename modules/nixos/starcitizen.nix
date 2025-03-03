{ config, inputs, lib, ... }:
let cfg = config.rhx.starcitizen;
in {
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  options.rhx.starcitizen.enable =
    lib.mkEnableOption "Enable starcitizen nixOS module";

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://nix-citizen.cachix.org" ];
      trusted-public-keys = [
        "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      ];
    };

    nix-citizen.starCitizen = {
      enable = true;
      # Additional commands before the game starts
      preCommands = ''
        export DXVK_HUD=compiler;
        export MANGO_HUD=1;
      '';
      # Experimental script
      helperScript.enable = true;
      # umu.enable = true;
    };
  };
}
