{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.helix;
in {
  options.rhx.helix = {
    enable = lib.mkEnableOption "Enable helix home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      package =
        inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
            backspace = {
              backspace = ":buffer-close";
              a = ":buffer-close-all";
              o = ":buffer-close-others";
              q = ":quit-all";
              Q = ":quit-all!";
            };
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
          };
          insert = {
            "F1" = "signature_help";
            "C-p" = "signature_help";
          };
        };
        # TODO: set this manually for work macbook
        # theme = "catppuccin_mocha";
      };

      languages = {
        language-server = {
          # ansible-language-server = {
          #   command =
          #     "${pkgs.ansible-language-server}/bin/ansible-language-server";
          # };
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
          omnisharp = { command = lib.getExe pkgs.omnisharp-roslyn; };
          ## rust
          rust-analyzer = { command = lib.getExe pkgs.rust-analyzer; };
          # for snippets
          scls = {
            command =
              "${pkgs.simple-completion-language-server}/bin/simple-completion-language-server";
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
            config = {
              schemas = [
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/deployment.json";
                  fileMatch = [ "*deployment*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/service.json";
                  fileMatch = [ "*service*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/configmap.json";
                  fileMatch = [ "*configmap*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/secret.json";
                  fileMatch = [ "*secret*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/pod.json";
                  fileMatch = [ "*pod*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/namespace.json";
                  fileMatch = [ "*namespace*.json" ];
                }
                {
                  uri =
                    "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/ingress.json";
                  fileMatch = [ "*ingress*.json" ];
                }
              ];
            };
          };
          yaml-language-server = {
            command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
            args = [ "--stdio" ];
            config = {
              yaml = {
                completion = true;
                hover = true;
                validate = false;
                schemaStore = { enable = true; };
                format = { enable = false; };
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
                  "http://json.schemastore.org/kustomization" =
                    "kustomization.{yml,yaml}";
                  "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
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
              args = [ "--parser" "json" ];
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
            auto-format = true;
            rulers = [ 80 ];
            formatter = {
              command = lib.getExe pkgs.deno;
              args = [ "fmt" "-" "--ext" "md" ];
            };
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
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            formatter = {
              command = lib.getExe pkgs.prettier;
              args = [ "--parser" "yaml" ];
            };
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
