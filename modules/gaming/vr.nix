{ ... }:
{
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wlx-overlay-s ];

      programs.alvr = {
        enable = true;
        openFirewall = true;
      };

      services = {
        monado.enable = true;
        wivrn = {
          enable = true;
          openFirewall = true;
        };
      };
    };
}
