{ inputs, pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
  };

  # environment.systemPackages = with pkgs; [
  #   xdg-desktop-portal-gtk
  # ];
}
