{ inputs, self, ... }:
{
  flake.nixosModules.hyprland =
    { config, pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        xwayland.enable = true;
      };

      xdg.portal = {
        enable = true;
      };

      # ryk.caelestia.enable = (isBarEnabled "caelestia");
      # ryk.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
      # ryk.noctalia.enable = (isBarEnabled "noctalia");

      home-manager.users.${config.ryk.meta.username}.imports = [ self.homeModules.hyprland ];
    };
}
