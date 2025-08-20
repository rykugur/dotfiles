{ pkgs, ... }:
let
  catppuccin-waybar = pkgs.fetchgit {
    url = "https://github.com/catppuccin/waybar";
    rev = "ee8ed32b4f63e9c417249c109818dcc05a2e25da";
    sha256 = "sha256-AAAAAAAAAAAAAAAA";
  };
in { }
