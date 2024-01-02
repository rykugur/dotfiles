{ config, inputs, lib, username, ... }: {
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  environment.systemPackages = [
    docker
    docker-compose
  ];

  users.users."${username}".extraGroups = [ "docker" ];
}
