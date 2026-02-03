{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ryk.virtualization.docker;
in
{
  options.ryk.virtualization.docker.enable =
    lib.mkEnableOption "Enable docker (virtualization) module";

  config = lib.mkIf cfg.enable {
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
