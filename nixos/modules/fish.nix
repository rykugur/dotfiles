{ config, inputs, lib, pkgs, username, ... }: {
  programs.fish.enable = true;

  users.users.${username}.shell = pkgs.fish;
}
