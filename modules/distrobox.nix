{ self, ... }:
{
  flake.nixosModules.distrobox =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [ virtiofsd ];

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      home-manager.users.${config.meta.ryk.username}.imports = [
        self.homeModules.distrobox
      ];
    };

  flake.homeModules.distrobox =
    { ... }:
    {
      programs.distrobox.enable = true;
    };
}
