{ ... }:
{
  flake.modules.nixos.razer =
    { username, pkgs, ... }:
    {
      hardware.openrazer = {
        enable = true;
        users = [ "${username}" ];
      };

      services.input-remapper.enable = true;

      environment.systemPackages = with pkgs; [ piper polychromatic ];
    };
}
