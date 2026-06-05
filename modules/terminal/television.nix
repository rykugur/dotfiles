{ ... }:
{
  flake.modules.homeManager.television =
    { config, lib, pkgs, ... }:
    {
      home.packages = [ pkgs.ripgrep ];

      programs.television = {
        enable = true;

        enableBashIntegration = config.programs.bash.enable;
        enableFishIntegration = config.programs.fish.enable;
        enableZshIntegration = config.programs.zsh.enable;

        settings = {
          ui = {
            theme = "catppuccin";
          };
          shell_integration.channel_triggers = {
            files = [ "cat" "less" "head" "tail" "vim" "nvim" "hx" "nano" "bat" "cp" "mv" "rm" "touch" "chmod" "chown" ];
          };
        };
      };

      # no programs.television.enableNushellIntegration option :(
      programs.nushell = lib.mkIf (config.programs.nushell.enable) {
        extraConfig = ''
          mkdir ($nu.data-dir | path join "vendor/autoload")
          ${lib.getExe pkgs.television} init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")
        '';
      };

      programs.television.channels =
        let
          sourceCmd = lib.concatStringsSep "; " (
            lib.optional config.programs.tmux.enable
              "tmux list-sessions -F '[tmux] #{session_name}' 2>/dev/null"
            ++ lib.optional config.programs.zellij.enable
              "zellij list-sessions -s 2>/dev/null | sed \"s/^/[zellij] /\""
          );
          # television doesn't run commands through a shell, so wrap in bash -c
          bashCmd = cmd: "bash -c '${cmd}'";
          # builds: bash -c 'line="{}"; if [[ "$line" == \[tmux\]* ]]; then <tcmd> "${line#\[tmux\] }"; else <zcmd> "${line#\[zellij\] }"; fi'
          branchCmd = tcmd: zcmd: bashCmd
            "line=\"{}\"; if [[ \"$line\" == \\[tmux\\]* ]]; then ${tcmd} \"\${line#\\[tmux\\] }\"; else ${zcmd} \"\${line#\\[zellij\\] }\"; fi";
        in {
          files = {
            metadata = {
              name = "files";
              description = "A channel to select files and directories";
              requirements = [ "fd" "bat" ];
            };
            source = {
              command = [
                "fd -t f"
                "fd -t f -H"
              ];
              # NOTE: files channel `source.display` (custom TV channel)
              #
              # Problem: We want the *folder path visible in the results list* for
              # disambiguation when there are duplicate basenames (default.nix,
              # index.ts, Cargo.toml, mod.rs, etc. are common and painful).
              # At the same time, fuzzy queries should primarily target *filenames*
              # (e.g. typing "riinto" should strongly prefer a file whose name
              # contains "rift-intel-tool" over an unrelated file that just lives
              # under a folder with that name in its path).
              #
              # How TV works here:
              # - `source.display` (when set) controls *both*:
              #   1. The string rendered in the results list (and what gets
              #      match highlights).
              #   2. The haystack string passed to the nucleo matcher (the single
              #      column that nucleo scores with its fzf-compatible
              #      Smith-Waterman + bonus system; TV also sets prefer_prefix).
              # - There is no separate "match template" vs "display template" in
              #   the channel TOML API (as of TV 0.15).
              # - The original raw line from the source command is still
              #   available as "{}", and is used for preview/actions/output
              #   unless `source.output` overrides it.
              #
              # Chosen template: "{split:/:-1}  {}"
              # - Puts the basename first → gets prefix/early-match position
              #   bonus and avoids leading gap penalties for filename queries.
              # - Appends the full original fd path (via "{}") → the complete
              #   folder location is visible inline in every list row.
              # - The basename also appears again at the end of the path, giving
              #   name matches a second strong alignment opportunity.
              # - Result list rows look like:
              #     "rift-intel-tool.nix  src/tools/rift-intel-tool.nix"
              #     "default.nix           project1/default.nix"
              #     "default.nix           project2/sub/default.nix"
              #     "index.ts              src/components/Foo/index.ts"
              #
              # Why this beats the previous attempts:
              # - Pure basename only ("{split:/:-1}"): path invisible in list
              #   (only in preview header) → bad for duplicates.
              # - Original attempt ("{split:/:-1}  {split:/:0..-1}"): path
              #   (without leaf) was visible, but folder names were still fully
              #   present in the matcher haystack and could outrank or pollute
              #   filename results.
              # - This version keeps full path visibility while structurally
              #   biasing the score toward the filename via position.
              #
              # Trade-off: If you type something that only exists in a folder
              # name (and not in any basename), you will still surface files
              # under that folder (because the path text is in the haystack for
              # visibility). Filename-intent queries win on score thanks to
              # early positioning + gap costs for pure path matches.
              #
              # Future iteration ideas:
              # - Try repeating the basename more explicitly for even stronger
              #   bias: "{split:/:-1} {split:/:-1}  {split:/:0..-1}"
              # - Experiment with different separators (" | ", " → ", etc.).
              # - Consider a composite source command that emits
              #   "basename<TAB>fullpath" + clever display + output split if we
              #   ever want multi-column-like behavior.
              # - If TV ever exposes a distinct "match" field separate from
              #   display, revisit.
              #
              # See the conversation in this chat (around the initial display
              # prop discussion) for the full exploration.
              display = "{split:/:-1}  {}";
            };
            ui.preview_panel.header = "{}";
            preview = {
              command = "bat -n --color=always '{}'";
              env.BAT_THEME = "ansi";
            };
            keybindings = {
              shortcut = "f1";
              f12 = "actions:edit";
              ctrl-up = "actions:goto_parent_dir";
            };
            actions.edit = {
              description = "Opens the selected entries with the default editor (falls back to vim)";
              command = "\${EDITOR:-vim} '{}'";
              shell = "bash";
              mode = "execute";
            };
            actions.goto_parent_dir = {
              description = "Re-opens tv in the parent directory";
              command = "tv files ..";
              mode = "execute";
            };
          };

          terminal-sessions = lib.mkIf
            (config.programs.tmux.enable || config.programs.zellij.enable)
            {
              metadata = {
                name = "terminal-sessions";
                description = "List and manage running tmux and zellij sessions";
              };
              source.command = bashCmd sourceCmd;
              preview.command = branchCmd "tmux list-windows -t" "echo";
              keybindings = {
                enter = "actions:attach";
                ctrl-d = "actions:kill";
              };
              actions.attach = {
                description = "Attach to the selected session";
                command = branchCmd "tmux attach -t" "zellij attach";
                mode = "execute";
              };
              actions.kill = {
                description = "Kill the selected session";
                command = branchCmd "tmux kill-session -t" "zellij kill-session";
                mode = "fork";
              };
            };
        };
    };
}
