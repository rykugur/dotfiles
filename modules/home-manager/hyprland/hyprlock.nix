{ pkgs, catppuccin-hyprland, ... }:
let
  catppuccin-hyprlock = pkgs.fetchgit {
    url = "https://github.com/catppuccin/hyprlock";
    rev = "958e70b1cd8799defd16dee070d07f977d4fd76b";
    sha256 = "sha256-l4CbAUeb/Tg603QnZ/VWxuGqRBztpHN0HLX/h8ndc5w=";
  };
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      source = [
        "${catppuccin-hyprlock}/hyprlock.conf"
        "${catppuccin-hyprland}/themes/mocha.conf"
      ];
    };
  };

}
