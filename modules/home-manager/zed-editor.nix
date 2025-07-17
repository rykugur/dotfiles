{ config, lib, pkgs, ... }:
let cfg = config.rhx.zed-editor;
in {
  options.rhx.zed-editor = {
    enable = lib.mkEnableOption "Enable zed-editor home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    # home.packages = [];
    programs.zed-editor = {
      enable = true;
      # package = pkgs.zed-editor-fhs;

      extraPackages = with pkgs; [ nil nixd ];

      extensions = [ "nix" "catppuccin" ];
      userSettings = {
        helix_mode = true;
        theme = "Catppuccin Mocha";

        # ui_font_size = lib.mkForce 12;
        # buffer_font_size = lib.mkForce 14;
        font_family = "FiraCode Nerd Font Mono";
        font_features = null;
        line_height = "comfortable";

        # indent_guides = {
        #   enabled = true;
        #   coloring = "indent_aware";
        # };
        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
          show_other_hints = true;
        };

        node = {
          path = lib.getExe pkgs.nodejs_22;
          npm_path = lib.getExe' pkgs.nodejs_22 "npm";
        };

        hour_format = "hour24";
        auto_update = false;

        lsp = {
          nix = { binary = { path_lookup = true; }; };
          # nil = { binary = { path = lib.getExe pkgs.nil; }; };
          # nixd = { binary = { path = lib.getExe pkgs.nixd; }; };
        };
        # languages = { nix = { language_servers = [ "nil" "nixd" ]; }; };
      };
    };

    home.file = {
      ".config/zed/snippets" = {
        source = ../../configs/snippets;
        recursive = true;
      };
    };
  };
}
