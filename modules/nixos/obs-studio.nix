{ config, lib, pkgs, ... }:
let cfg = config.rhx.obs-studio;
in {
  options.rhx.obs-studio.enable =
    lib.mkEnableOption "Enable obs-studio nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ libva-utils ];

    programs.obs-studio = {
      enable = true;

      plugins = with pkgs.obs-studio-plugins; [
        input-overlay
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi
        obs-gstreamer
        obs-vkcapture
      ];
    };
  };
}
