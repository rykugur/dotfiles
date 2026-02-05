{ ... }:
{
  flake.homeModules.helix-settings =
    { pkgs, ... }:
    {
      programs.helix.settings = {
        editor = {
          bufferline = "multiple";
          cursorcolumn = false;
          cursorline = true;
          clipboard-provider = "${if pkgs.stdenv.isDarwin then "pasteboard" else "wayland"}";
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          end-of-line-diagnostics = "hint";
          file-picker = {
            hidden = false;
          };
          indent-guides = {
            render = true;
          };
          inline-diagnostics = {
            cursor-line = "error";
          };
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
            space = {
              t = {
                h = ":toggle cursorline";
                i = ":toggle lsp.display-inlay-hints";
                v = ":toggle cursorcolumn";
              };
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
    };
}
