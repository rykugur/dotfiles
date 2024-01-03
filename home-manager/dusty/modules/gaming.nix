{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    discord
    betterdiscordctl

    protontricks

    obs-studio
    obs-cli
  ];
}
