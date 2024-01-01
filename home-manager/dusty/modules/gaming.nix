{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    discord
    betterdiscordctl

    obs-studio
    obs-cli
  ];
}
