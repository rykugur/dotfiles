{ ... }:
{
  flake.modules.homeManager.zed-editor =
    { lib, pkgs, ... }:
    {
      # home.packages = [];
      programs.zed-editor = {
        enable = true;
        package = if pkgs.stdenv.isLinux then pkgs.zed-editor-fhs else pkgs.zed-editor;

        extraPackages = with pkgs; [
          nil
          nixd
        ];

        extensions = [
          "nix"
          "catppuccin"
          "catppuccin-icons"
          "helm"
        ];
        userSettings = {
          helix_mode = true;
          extraPackages = [
            pkgs.dotnet-sdk_8
            pkgs.icu
            pkgs.nixfmt
          ];

          # ui_font_size = lib.mkForce 12;
          # buffer_font_size = lib.mkForce 14;
          font_family = "CaskaydiaCove NFM";
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
            nix = {
              binary = {
                path_lookup = true;
              };
            };
          };
          languages = {
            CSharp = {
              formatter = "language_server";
            };
            Nix = {
              formatter = {
                external = {
                  command = "nixfmt";
                };
              };
              language_servers = [
                "nil"
                "!nixd"
              ];
            };
          };
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
