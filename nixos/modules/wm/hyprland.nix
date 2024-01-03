{ config, inputs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
