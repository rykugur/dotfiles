{ pkgs, ... }: {
  hardware.pulseaudio.enable = false;

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
    };
  };

  users.users."dusty".extraGroups = [ "audio" ];
}
