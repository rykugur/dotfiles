{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.pipewirez;
in {
  options = {
    services.pipewirez.enable = lib.mkEnableOption "Enable pipewire.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.pulseaudio
      pkgs.alsa-utils # for amixer
    ];

    services = {
      pipewire = {
        enable = true;

        # doesn't seem to be necessary anymore with easy effects
        # may remove later
        # extraConfig.pipewire-pulse = {
        #   "95-load-echo-cancel" = {
        #     "pulse.cmd" = [
        #       {
        #         cmd = "load-module";
        #         args = "module-echo-cancel";
        #       }
        #     ];
        #   };
        # };

        # alsa is not required but helpful for 32 bit apps, particularly older games
        alsa = {
          enable = true;
          support32Bit = true;
        };

        pulse.enable = true;

        # lowLatency = {
        #   # enable this module
        #   enable = true;
        #   # defaults (no need to be set unless modified)
        #   quantum = 64;
        #   rate = 48000;
        # };
      };
    };

    # make pipewire realtime-capable
    security.rtkit.enable = true;

    users.users.${username}.extraGroups = ["audio"];
  };
}
