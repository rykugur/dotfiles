{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.helix;
  sclsPkg = inputs.scls.defaultPackage.${pkgs.system};
in {
  options.rhx.helix = {
    enable = lib.mkEnableOption "Enable helix home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      package = inputs.helix.packages.${pkgs.system}.default;
      settings = {
        editor = {
          bufferline = "multiple";
          clipboard-provider =
            "${if pkgs.stdenv.isDarwin then "pasteboard" else "wayland"}";
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          end-of-line-diagnostics = "hint";
          file-picker = { hidden = false; };
          indent-guides = { render = true; };
          inline-diagnostics = { cursor-line = "error"; };
          lsp = {
            auto-signature-help = false;
            display-inlay-hints = true;
          };
          middle-click-paste = true;
        };
        keys = {
          normal = {
            "K" = "hover";
            "S-h" = "goto_previous_buffer";
            "S-l" = "goto_next_buffer";
            # "A-k" = "keep_selections";
            # "space" = { "e" = "file_browser"; };
          };
          insert = { "F1" = "signature_help"; };
        };
        theme = "catppuccin_mocha";
      };
      languages = {
        language-server = {
          ansible-language-server = {
            command =
              "${pkgs.ansible-language-server}/bin/ansible-language-server";
          };
          golangci-lint-lsp = {
            command =
              "${pkgs.golangci-lint-langserver}/bin/golangci-lint-langserver";
          };
          gopls = { command = "${pkgs.gopls}/bin/gopls"; };
          lua-language-server = {
            command = "${pkgs.lua-language-server}/bin/lua-language-server";
          };
          helm_ls = { command = "${pkgs.helm-ls}/bin/helm_ls"; };
          marksman = with pkgs; { command = "${marksman}/bin/marksman"; };
          markdown-oxide = with pkgs; {
            command = "${markdown-oxide}/bin/markdown-oxide";
          };
          nixd = { command = "${pkgs.nixd}/bin/nixd"; };
          nil = { command = "${pkgs.nil}/bin/nil"; };
          nu = { command = "${pkgs.nushell}/bin/nu"; };
          # for snippets
          scls = {
            command = "${sclsPkg}/bin/simple-completion-language-server";
          };
          taplo = { command = "${pkgs.taplo}/bin/taplo"; };
          typescript-language-server = {
            # vtsls seems to be better, and fixes a weird error I was getting on _some_ files.
            command = "${pkgs.vtsls}/bin/vtsls";
            # command = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
          };
          vscode-json-language-server = with pkgs.nodePackages; {
            command =
              "${vscode-json-languageserver}/bin/vscode-json-languageserver";
          };
          yaml-language-server = {
            command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
          };
        };
        language = [
          {
            name = "helm";
            auto-format = false;
          }
          {
            name = "javascript";
            auto-format = true;
            language-servers = [ "typescript-language-server" "scls" ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "jsx";
            auto-format = true;
            language-servers = [ "typescript-language-server" "scls" ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "lua";
            auto-format = true;
            formatter = { command = "${pkgs.luaformatter}/bin/lua-format"; };
          }
          {
            name = "markdown";
            rulers = [ 80 ];
          }
          {
            name = "nix";
            auto-format = true;
            formatter = { command = "${pkgs.nixfmt-classic}/bin/nixfmt"; };
          }
          {
            name = "typescript";
            auto-format = true;
            language-servers = [ "typescript-language-server" "scls" ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "tsx";
            auto-format = true;
            language-servers = [ "typescript-language-server" "scls" ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "yaml";
            auto-format = false;
            formatter = { command = "${pkgs.yamlfmt}/bin/yamlfmt"; };
          }
        ];
      };
    };

    home.file = {
      ".config/helix/snippets" = {
        source = ../../configs/helix/snippets;
        recursive = true;
      };
    };
  };
}
