{ config, inputs, lib, pkgs, ... }: {
  home.packages = [
    pkgs.obs-studio
    pkgs.obs-cli
    pkgs.obs-studio-plugins.input-overlay
    pkgs.obs-studio-plugins.wlrobs
  ];
}
