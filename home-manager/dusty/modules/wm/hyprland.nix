{ config, inputs, lib, ... }: {
  home.file = {
    ".config/hypr" = {
      source = ../../../../configs/hypr;
    };
    ".config/waybar" = {
      source = ../../../../configs/waybar;
      recursive = true;
    };
  };
}
