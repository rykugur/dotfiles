{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.btop;
  catppuccin-btop = pkgs.fetchgit {
    url = "https://github.com/catppuccin/btop?tab=readme-ov-file";
    rev = "f437574b600f1c6d932627050b15ff5153b58fa3";
    sha256 = lib.fakeSha256;
  };

  themesDir = "${catppuccin-btop}/themes";
  themeFiles = builtins.readDir themesDir;
  # map theme name -> theme content
  formattedThemes = builtins.listToAttrs (builtins.map (name: {
    name = builtins.replaceStrings [ ".theme" ] [ "" ] name;
    value = builtins.readFile "${themesDir}/${name}";
  }) (builtins.attrNames (builtins.filterAttrs
    (name: type: type == "regular" && builtins.match ".*\\.theme$" name != null)
    themeFiles)));

in {
  options.rhx.btop = {
    enable = lib.mkEnableOption "Enable btop home-manager module.";
    # TODO: would be cool to genericize this
    theme = lib.mkOption {
      type = lib.types.enum [
        "catppuccin-mocha"
        "catppuccin-latte"
        "catppuccin-macchiato"
        "catppuccin-frappe"
      ];
      default = "catppuccin-mocha";
      description =
        "Select a Catppuccin theme for btop. Available themes are catppuccin-mocha, catppuccin-latte, catppuccin-macchiato, and catppuccin-frappe.";
    };

  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
      themes = formattedThemes;

      setings = {
        color_theme = "${config.theme}";
        theme_background = false;
      };
    };
  };
}
