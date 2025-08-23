{ pkgs, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      source = [
        "${pkgs.catppuccin-ports.hyprlock}/hyprlock.conf"
        "${pkgs.catppuccin-ports.hyprland}/themes/mocha.conf"
      ];
    };
  };

}
