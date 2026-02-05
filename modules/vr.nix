{ ... }:
{
  flake.nixosModules.vr =
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

      # home-manager.users.${username}.imports = [ self.homeModules.vr ];
    };
}
