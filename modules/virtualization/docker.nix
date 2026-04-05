{ ... }:
{
  flake.modules.nixos.docker =
    { username, lib, pkgs, ... }:
    {
      virtualisation.docker = {
        enable = true;
        storageDriver = lib.mkDefault "btrfs";
      };

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      users.users.${username}.extraGroups = [ "docker" ];
    };
}
