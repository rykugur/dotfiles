{ pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    enableNvidia = true;
  };

  # TODO: pass these args to docker
  # --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=compute,utility -e NVIDIA_VISIBLE_DEVICES=al

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];

  users.users."dusty".extraGroups = [ "docker" ];
}
