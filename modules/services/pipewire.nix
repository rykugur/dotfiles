{ config, lib, pkgs, username, ... }:
let cfg = config.modules.services.pipewire;
in {
  options.modules.services.pipewire.enable =
    lib.mkEnableOption "Enable pipewire.";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.pulseaudio
      pkgs.alsa-utils # for amixer
    ];

    services = {
      pipewire = {
        enable = true;
        # alsa is not required but helpful for 32 bit apps, particularly older games
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };

    # make pipewire realtime-capable
    security.rtkit.enable = true;

    users.users.${username}.extraGroups = [ "audio" ];
  };
}
