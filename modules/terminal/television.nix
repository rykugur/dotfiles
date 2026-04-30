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
              display = "{split:/:-1}  {split:/:0..-1}";
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
