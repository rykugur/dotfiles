{ ... }:
{
  flake.nixosModules.obs-studio =
    { pkgs, ... }:
    {

      environment.systemPackages = with pkgs; [ libva-utils ];

      programs.obs-studio = {
        enable = true;

        plugins = with pkgs.obs-studio-plugins; [
          input-overlay
          wlrobs
          obs-backgroundremoval
          obs-composite-blur
          obs-move-transition
          obs-pipewire-audio-capture
          obs-vaapi
          obs-gstreamer
          obs-vkcapture
        ];
      };
    };
}
