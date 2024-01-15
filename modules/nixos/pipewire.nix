{ inputs, pkgs, ... }: {
  hardware.pulseaudio = {
    enable = false;

    extraConfig = ''
      load-module module-echo-cancel
    '';
  };

  environment.systemPackages = [
    pkgs.pulseaudio
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
        # enable this module
        enable = true;
        # defaults (no need to be set unless modified)
        quantum = 64;
        rate = 48000;
      };
    };
  };

  # make pipewire realtime-capable
  security.rtkit.enable = true;

  users.users."dusty".extraGroups = [ "audio" ];
}
