{ config, inputs, lib, username, ... }: {
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  users.users."${username}".extraGroups = [ "docker" ];
}
