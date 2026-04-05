{ self, ... }:
{
  flake.modules.nixos.audiorelay =
    { username, ... }:
    {
      networking.firewall = {
        allowedTCPPorts = [ 59100 ];
        allowedUDPPorts = [ 59100 ];
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.audiorelay ];
    };

  flake.modules.homeManager.audiorelay =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.audiorelay ];
    };
}
