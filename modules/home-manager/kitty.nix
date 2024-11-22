{ config, lib, ... }:
let cfg = config.rhx.kitty;
in {
  options.rhx.kitty = {
    enable = lib.mkEnableOption "Enable kitty home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = "CaskaydiaCove Nerd Font Mono Regular";
        bold_font = "CaskaydiaCove Nerd Font Mono Bold";
        italic_font = "CaskaydiaCove Nerd Font Mono Italic";
        bold_italic_font = "CaskaydiaCove Nerd Font Mono Bold Italic";
        font_size = 11.0;
        enable_audio_bell = "no";
        remember_window_size = "no";
        initial_window_width = "160c";
        initial_window_height = "40c";
      };
      themeFile = "Catppuccin-Mocha";
    };
  };
}
