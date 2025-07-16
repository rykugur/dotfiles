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
            snippets = true;
          };
          middle-click-paste = true;
        };
        keys = {
          normal = {
            "K" = "hover";
            "S-h" = "goto_previous_buffer";
            "S-l" = "goto_next_buffer";
            "S-z" = [
              ":sh rm -f /tmp/unique-file"
              ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
              '':insert-output echo "\x1b[?1049h\x1b[?2004h" > /dev/tty''
              ":open %sh{cat /tmp/unique-file}"
              ":redraw"
            ];
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
          tailwindcss-ls = {
            command =
              "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
          };
          taplo = { command = "${pkgs.taplo}/bin/taplo"; };
          typescript-language-server = { command = "${pkgs.vtsls}/bin/vtsls"; };
          vscode-css-language-server = {
            command =
              "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
          };
          vscode-eslint-language-server = {
            command =
              "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
            config = {
              format = false;
              quiet = false;
              rulesCustomizations = [ ];
              run = "onType";
              validate = "on";
              codeAction = {
                disableRuleComment = {
                  enable = true;
                  location = "separateLine";
                };
                showDocumentation = { enable = true; };
              };
              experimental = { useFlatConfig = true; };
              problems = { shortenToSingleLine = false; };
            };
          };
          vscode-html-language-server = {
            command =
              "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
          };
          vscode-json-language-server = {
            command =
              "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          };
          yaml-language-server = {
            command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
            config = {
              yaml = {
                completion = true;
                validation = true;
                hover = true;
                schemas = {
                  kubernetes = [
                    "*deployment*.yaml"
                    "*service*.yaml"
                    "*configmap*.yaml"
                    "*secret*.yaml"
                    "*pod*.yaml"
                    "*namespace*.yaml"
                    "*ingress*.yaml"
                  ];
                  "https://json.schemastore.org/github-workflow.json" =
                    ".github/workflows/*.yaml";
                  "https://json.schemastore.org/docker-compose.yml" =
                    "docker-compose*.yaml";
                  "https://json.schemastore.org/kustomization.json" =
                    "kustomization.yaml";
                  "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/kustomization.json" =
                    [ "*kustomization.yaml" "*kustomize.yaml" ];
                  "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
                    [ "*workflow*.yaml" "*template*.yaml" ];
                };
              };
            };
          };
        };

        language = [
          {
            name = "css";
            language-servers =
              [ "vscode-css-language-server" "tailwindcss-ls" ];
          }
          {
            name = "helm";
            auto-format = false;
          }
          {
            name = "html";
            language-servers =
              [ "vscode-html-language-server" "tailwindcss-ls" ];
          }
          {
            name = "javascript";
            auto-format = true;
            language-servers = [
              "typescript-language-server"
              "vscode-eslint-language-server"
              "scls"
            ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "json";
            auto-format = true;
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "jsx";
            auto-format = true;
            language-servers = [
              "typescript-language-server"
              "vscode-eslint-language-server"
              "tailwindcss-ls"
              "scls"
            ];
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
            language-servers = [
              "typescript-language-server"
              "vscode-eslint-language-server"
              "scls"
            ];
            formatter = {
              command = "${pkgs.nodePackages.prettier}/bin/prettier";
              args = [ "--parser" "typescript" ];
            };
          }
          {
            name = "tsx";
            auto-format = true;
            language-servers = [
              "typescript-language-server"
              "vscode-eslint-language-server"
              "tailwindcss-ls"
              "scls"
            ];
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
        source = ../../configs/snippets;
        recursive = true;
      };
    };
  };
}
