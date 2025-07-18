{ config, lib, username, pkgs, ... }:
let cfg = config.rhx.distrobox;
in {
  options.rhx.distrobox.enable =
    lib.mkEnableOption "Enable distrobox nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ virtiofsd ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    home-manager.users.${username} = { programs.distrobox.enable = true; };
  };
}
