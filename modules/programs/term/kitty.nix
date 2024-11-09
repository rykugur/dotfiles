{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.term.kitty;
in {
  options.modules.programs.term.kitty.enable =
    lib.mkEnableOption "Enable kitty";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # TODO: better understand this, appears to be required to get the HM config
      pkgs, ... }: {
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
            shell = "${pkgs.nushell}/bin/nu";
          };
          themeFile = "Catppuccin-Mocha";
        };
      };
  };
}
