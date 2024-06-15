{ config, lib, pkgs, ... }:
let cfg = config.services.docker;
in {
  options = { services.docker.enable = lib.mkEnableOption "Enable docker"; };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
      enableNvidia = true;
    };

    # TODO: pass these args to docker
    # --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=compute,utility -e NVIDIA_VISIBLE_DEVICES=al

    environment.systemPackages = with pkgs; [ docker docker-compose ];

    users.users."dusty".extraGroups = [ "docker" ];
  };
}
