{ config, lib, pkgs, ... }:
let cfg = config.modules.services.docker;
in {
  options.modules.services.docker.enable = lib.mkEnableOption "Enable docker";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
      # TODO: figure out how to conditionally enable this
      # enableNvidia = true;
    };

    # TODO: pass these args to docker
    # --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=compute,utility -e NVIDIA_VISIBLE_DEVICES=al

    environment.systemPackages = with pkgs; [ docker docker-compose ];

    users.users."dusty".extraGroups = [ "docker" ];
  };
}
