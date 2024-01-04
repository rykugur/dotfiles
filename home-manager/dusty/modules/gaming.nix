{ config, inputs, lib, pkgs, ... }: {
  home.packages = [
    (pkgs.discord.override {
      nss = pkgs.nss_latest;
    })
    pkgs.betterdiscordctl

    pkgs.protontricks

    pkgs.obs-studio
    pkgs.obs-cli
  ];
}
