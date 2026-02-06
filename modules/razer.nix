{ ... }:
{
  flake.nixosModules.razer =
    { config, pkgs, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {

      hardware.openrazer = {
        enable = true;
        users = [ "${metaCfg.username}" ];
      };

      services = {
        input-remapper.enable = true;
      };

      environment.systemPackages = with pkgs; [
        piper
        polychromatic
      ];
    };
}
