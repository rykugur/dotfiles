{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.pipewire;
in {
  options.rhx.pipewire.enable =
    lib.mkEnableOption "Enable pipewire nixOS module";

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

        lowLatency = {
          enable = true;
          quantum = 2048;
          rate = 48000;
        };
      };
    };

    # make pipewire realtime-capable
    security.rtkit.enable = true;

    users.users.${username}.extraGroups = [ "audio" ];
  };
}
