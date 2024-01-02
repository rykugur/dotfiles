{ config, inputs, libs, username, ... }: {
  hardware.pulseaudio.enable = false;

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

  users.users."${username}".extraGroups = [ "audio" ];
}