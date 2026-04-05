{ self, ... }:
{
  flake.modules.nixos.distrobox =
    { username, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ virtiofsd ];

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.distrobox ];
    };

  flake.modules.homeManager.distrobox =
    { ... }:
    {
      programs.distrobox.enable = true;
    };
}
