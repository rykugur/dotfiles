{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    discord
    betterdiscordctl
  ];
}
