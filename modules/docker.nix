{ ... }:
{
  flake.nixosModules.docker =
    { lib, pkgs, ... }:
    {
      virtualisation.docker = {
        enable = true;
        storageDriver = lib.mkDefault "btrfs";
      };

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      users.users."dusty".extraGroups = [ "docker" ];
    };

}
