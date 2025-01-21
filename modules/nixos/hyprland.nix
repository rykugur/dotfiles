{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.hyprland;
in {
  options.rhx.hyprland.enable =
    lib.mkEnableOption "Enable hyprland nixOS module";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    xdg.portal = { enable = true; };

    nix.settings = {
      # TODO: move these to respective module files
      substituters = [
        "https://hyprland.cachix.org"
        #   "https://nix-gaming.cachix.org"
        #   "https://nix-citizen.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        #   "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        #   "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      ];
    };
  };
}
