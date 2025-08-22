{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.btop;

  themesDir = "${pkgs.catppuccin-ports.btop}/themes";
  themeFiles = builtins.readDir themesDir;
  # map theme name -> theme content
  formattedThemes = builtins.listToAttrs (builtins.map (name: {
    name = builtins.replaceStrings [ ".theme" ] [ "" ] name;
    value = builtins.readFile "${themesDir}/${name}";
  }) (builtins.attrNames (lib.filterAttrs
    (name: type: type == "regular" && builtins.match ".*\\.theme$" name != null)
    themeFiles)));

in {
  options.rhx.btop = {
    enable = lib.mkEnableOption "Enable btop home-manager module.";
    # TODO: would be cool to genericize this
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
      themes = formattedThemes;

      settings = {
        color_theme = config.rhx.hyprland.theme;
        theme_background = false;
      };
    };
  };
}
