{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.zellij;
  zellij-autolock = pkgs.fetchurl {
    url =
      "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.1/zellij-autolock.wasm";
    sha256 = "sha256-3KvHgNdJdb8Nd83OxxrKFuzM6nAjn0G0wyebOI9zs40=";
  };
  zjstatus-pkg = inputs.zjstatus.packages.${pkgs.system}.default;
in {
  options.rhx.zellij = {
    enable = lib.mkEnableOption "Enable zellij home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    # home.packages = [ inputs.zjstatus.packages.${pkgs.system}.default ];

    programs.zellij = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        plugins = {
          "autolock location=\"file:${
            builtins.unsafeDiscardStringContext zellij-autolock
          }\"" = {
            # Enabled at start?
            is_enabled = true;
            # Lock when any open these programs open.
            triggers = "nvim|vim|git|fzf|zoxide|atuin";
            # Reaction to input occurs after this many seconds. (default=0.3)
            # (An existing scheduled reaction prevents additional reactions.)
            reaction_seconds = "0.3";
            # Print to Zellij log? (default=false)
            print_to_log = true;
          };
        };
        keybinds = {
          normal = {
            # "bind \"Ctrl h\"" = { MoveFocusOrTab = "Left"; };
            # "bind \"Ctrl j\"" = { MoveFocusOrTab = "Down"; };
            # "bind \"Ctrl k\"" = { MoveFocusOrTab = "Up"; };
            # "bind \"Ctrl l\"" = { MoveFocusOrTab = "Right"; };
            "bind \"Ctrl h\"" = { MoveFocus = "Left"; };
            "bind \"Ctrl j\"" = { MoveFocus = "Down"; };
            "bind \"Ctrl k\"" = { MoveFocus = "Up"; };
            "bind \"Ctrl l\"" = { MoveFocus = "Right"; };
          };
        };
        load_plugins = [ "autolock" ];
      };
    };

    xdg.configFile."zellij/layouts/default.kdl".text = ''
      layout {
        default_tab_template {
          children
          pane size=1 borderless=true {
            plugin location="file:${zjstatus-pkg}/bin/zjstatus.wasm" {
              format_left   "{mode}#[bg=#181926] {tabs}"
              format_center ""
              format_right  "#[bg=#181926,fg=#89b4fa]#[bg=#89b4fa,fg=#1e2030,bold] #[bg=#363a4f,fg=#89b4fa,bold] {session} #[bg=#181926,fg=#363a4f,bold]"
              format_space  ""
              format_hide_on_overlength "true"
              format_precedence "crl"

              border_enabled  "false"
              border_char     "─"
              border_format   "#[fg=#6C7086]{char}"
              border_position "top"

              mode_normal        "#[bg=#a6da95,fg=#181926,bold] NORMAL#[bg=#181926,fg=#a6da95]█"
              mode_locked        "#[bg=#6e738d,fg=#181926,bold] LOCKED #[bg=#181926,fg=#6e738d]█"
              mode_resize        "#[bg=#f38ba8,fg=#181926,bold] RESIZE#[bg=#181926,fg=#f38ba8]█"
              mode_pane          "#[bg=#89b4fa,fg=#181926,bold] PANE#[bg=#181926,fg=#89b4fa]█"
              mode_tab           "#[bg=#b4befe,fg=#181926,bold] TAB#[bg=#181926,fg=#b4befe]█"
              mode_scroll        "#[bg=#f9e2af,fg=#181926,bold] SCROLL#[bg=#181926,fg=#f9e2af]█"
              mode_enter_search  "#[bg=#8aadf4,fg=#181926,bold] ENT-SEARCH#[bg=#181926,fg=#8aadf4]█"
              mode_search        "#[bg=#8aadf4,fg=#181926,bold] SEARCHARCH#[bg=#181926,fg=#8aadf4]█"
              mode_rename_tab    "#[bg=#b4befe,fg=#181926,bold] RENAME-TAB#[bg=#181926,fg=#b4befe]█"
              mode_rename_pane   "#[bg=#89b4fa,fg=#181926,bold] RENAME-PANE#[bg=#181926,fg=#89b4fa]█"
              mode_session       "#[bg=#74c7ec,fg=#181926,bold] SESSION#[bg=#181926,fg=#74c7ec]█"
              mode_move          "#[bg=#f5c2e7,fg=#181926,bold] MOVE#[bg=#181926,fg=#f5c2e7]█"
              mode_prompt        "#[bg=#8aadf4,fg=#181926,bold] PROMPT#[bg=#181926,fg=#8aadf4]█"
              mode_tmux          "#[bg=#f5a97f,fg=#181926,bold] TMUX#[bg=#181926,fg=#f5a97f]█"

              // formatting for inactive tabs
              tab_normal              "#[bg=#181926,fg=#89b4fa]█#[bg=#89b4fa,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#89b4fa,bold] {name}{floating_indicator}#[bg=#181926,fg=#363a4f,bold]█"
              tab_normal_fullscreen   "#[bg=#181926,fg=#89b4fa]█#[bg=#89b4fa,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#89b4fa,bold] {name}{fullscreen_indicator}#[bg=#181926,fg=#363a4f,bold]█"
              tab_normal_sync         "#[bg=#181926,fg=#89b4fa]█#[bg=#89b4fa,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#89b4fa,bold] {name}{sync_indicator}#[bg=#181926,fg=#363a4f,bold]█"

              // formatting for the current active tab
              tab_active              "#[bg=#181926,fg=#fab387]█#[bg=#fab387,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#fab387,bold] {name}{floating_indicator}#[bg=#181926,fg=#363a4f,bold]█"
              tab_active_fullscreen   "#[bg=#181926,fg=#fab387]█#[bg=#fab387,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#fab387,bold] {name}{fullscreen_indicator}#[bg=#181926,fg=#363a4f,bold]█"
              tab_active_sync         "#[bg=#181926,fg=#fab387]█#[bg=#fab387,fg=#1e2030,bold]{index} #[bg=#363a4f,fg=#fab387,bold] {name}{sync_indicator}#[bg=#181926,fg=#363a4f,bold]█"

              // separator between the tabs
              tab_separator           "#[bg=#181926] "

              // indicators
              tab_sync_indicator       " "
              tab_fullscreen_indicator " 󰊓"
              tab_floating_indicator   " 󰹙"

              command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
              command_git_branch_format      "#[fg=blue] {stdout} "
              command_git_branch_interval    "10"
              command_git_branch_rendermode  "static"

              datetime        "#[fg=#6C7086,bold] {format} "
              datetime_format "%A, %d %b %Y %H:%M"
              datetime_timezone "America/Chicago"
            }
          }
        }
      }'';
  };
}
