{ pkgs, ... }:
{
  imports = [
    ../../home
  ];

  home.packages = with pkgs; [
    nh
    nix-prefetch-scripts

    _1password-cli
    fd
    tldr
  ];

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
