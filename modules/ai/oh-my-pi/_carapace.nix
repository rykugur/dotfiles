let
  rootFlags = {
    "--model" = "Model to use";
    "--smol" = "Smol/fast model for lightweight tasks";
    "--slow" = "Slow/reasoning model for thorough analysis";
    "--plan" = "Plan model for architectural planning";
    "--provider" = "Provider to use";
    "--api-key" = "API key";
    "--system-prompt" = "System prompt";
    "--append-system-prompt" = "Append text or file contents to the system prompt";
    "--allow-home" = "Allow starting in ~ without auto-switching to a temp dir";
    "--profile" = "Use an isolated profile";
    "--alias" = "Create a shell shortcut for the selected profile and exit";
    "--cwd" = "Directory to start in";
    "--mode" = "Output mode";
    "--config" = "Load an extra config.yml-style overlay";
    "-p" = "Non-interactive mode";
    "--print" = "Non-interactive mode";
    "-c" = "Continue previous session";
    "--continue" = "Continue previous session";
    "-r" = "Resume a session";
    "--resume" = "Resume a session";
    "--session-dir" = "Directory for session storage and lookup";
    "--no-session" = "Do not save session";
    "--models" = "Comma-separated model patterns for model cycling";
    "--no-tools" = "Disable all built-in tools";
    "--no-lsp" = "Disable LSP tools, formatting, and diagnostics";
    "--no-pty" = "Disable PTY-based interactive bash execution";
    "--tools" = "Comma-separated list of tools to enable";
    "--thinking" = "Set thinking level";
    "--hide-thinking" = "Hide thinking blocks in TUI output";
    "--advisor" = "Enable the advisor runtime";
    "--hook" = "Load a hook or extension file";
    "-e" = "Load an extension file";
    "--extension" = "Load an extension file";
    "--no-extensions" = "Disable extension discovery";
    "--no-skills" = "Disable skills discovery and loading";
    "--skills" = "Comma-separated glob patterns to filter skills";
    "--no-rules" = "Disable rules discovery and loading";
    "--export" = "Export session file to HTML and exit";
    "--no-title" = "Disable title auto-generation";
    "--print-thoughts" = "Include thinking blocks in print mode text output";
    "--max-time" = "Stop the session after this many seconds";
    "--auto-approve" = "Auto-approve all tool calls";
    "--approval-mode" = "Override tools.approvalMode";
  };

in
{
  spec = {
    name = "omp";
    description = "Oh My Pi coding agent";
    flags = rootFlags;
    completion = {
      flag = {
        mode = [
          "text"
          "json"
          "rpc"
          "acp"
          "rpc-ui"
        ];
        thinking = [
          "off"
          "minimal"
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
          "auto"
        ];
        approval-mode = [
          "always-ask"
          "write"
          "yolo"
        ];
      };
      positional = [
        [
          "acp\tRun Oh My Pi as an ACP server over stdio"
          "agents\tManage bundled task agents"
          "auth-broker\tManage the omp auth-broker"
          "auth-gateway\tRun an auth-gateway forward proxy"
          "bench\tBenchmark models"
          "commit\tGenerate a commit message and update changelogs"
          "completions\tPrint a shell completion script"
          "config\tManage configuration settings"
          "dry-balance\tDry-run OAuth account balancing"
          "gallery\tPreview tool renderers"
          "gc\tRun storage garbage collection"
          "grep\tTest grep tool"
          "grievances\tView, clean, or push reported tool issues"
          "install\tInstall or link an extension package"
          "join\tJoin a shared collab session"
          "models\tList, search, and refresh available models"
          "plugin\tManage plugins"
          "read\tShow what the read tool will return"
          "say\tSynthesize text with the local TTS engine"
          "search\tTest web search providers"
          "q\tTest web search providers"
          "setup\tRun onboarding setup or install optional dependencies"
          "shell\tInteractive shell console"
          "ssh\tManage SSH host configurations"
          "stats\tView usage statistics"
          "tiny-models\tDownload tiny local models"
          "token\tGet the API key or OAuth token for a provider"
          "ttsr\tInspect and test Time-Traveling Stream Rules"
          "update\tCheck for and install updates"
          "usage\tShow provider usage limits"
          "worktree\tList or clear agent-managed git worktrees"
          "wt\tList or clear agent-managed git worktrees"
        ]
      ];
    };
    commands = [
      {
        name = "completions";
        description = "Print a shell completion script";
        completion.positional = [
          [
            "bash"
            "zsh"
            "fish"
          ]
        ];
      }
      {
        name = "config";
        description = "Manage configuration settings";
        flags = {
          "--json" = "Output JSON";
        };
        completion.positional = [
          [
            "list"
            "get"
            "set"
            "reset"
            "path"
            "init-xdg"
          ]
        ];
      }
      {
        name = "plugin";
        description = "Manage plugins";
        flags = {
          "--json" = "Output JSON";
          "--fix" = "Attempt to fix issues";
          "--force" = "Force install";
          "--dry-run" = "Show actions without applying changes";
          "-l" = "Operate on local plugin directory";
          "--local" = "Operate on local plugin directory";
          "--enable" = "Enable a feature";
          "--disable" = "Disable a feature";
          "--set" = "Set plugin config";
          "--scope" = "Install scope";
        };
        completion = {
          flag.scope = [
            "user"
            "project"
          ];
          positional = [
            [
              "install"
              "uninstall"
              "list"
              "link"
              "doctor"
              "features"
              "config"
              "enable"
              "disable"
              "marketplace"
              "discover"
              "upgrade"
            ]
          ];
        };
      }
      {
        name = "search";
        aliases = [ "q" ];
        description = "Test web search providers";
        flags = {
          "--provider" = "Search provider";
          "--recency" = "Recency filter";
          "-l" = "Max results to return";
          "--limit" = "Max results to return";
          "--compact" = "Render condensed output";
        };
        completion.flag = {
          provider = [
            "auto"
            "perplexity"
            "gemini"
            "anthropic"
            "codex"
            "xai"
            "zai"
            "exa"
            "tinyfish"
            "jina"
            "kagi"
            "tavily"
            "firecrawl"
            "brave"
            "kimi"
            "parallel"
            "synthetic"
            "searxng"
            "startpage"
            "duckduckgo"
            "bing"
            "yahoo"
            "ecosia"
            "google"
            "mojeek"
            "public"
          ];
          recency = [
            "day"
            "week"
            "month"
            "year"
          ];
        };
      }
      {
        name = "setup";
        description = "Run onboarding setup or install optional dependencies";
        flags = {
          "-c" = "Check if dependencies are installed";
          "--check" = "Check if dependencies are installed";
          "--json" = "Output status as JSON";
        };
        completion.positional = [
          [
            "python"
            "speech"
          ]
        ];
      }
      {
        name = "worktree";
        aliases = [ "wt" ];
        description = "List or clear agent-managed git worktrees";
        flags = {
          "--all" = "Clear every entry";
          "-n" = "Dry run";
          "--dry-run" = "Dry run";
          "-j" = "Emit JSON";
          "--json" = "Emit JSON";
        };
        completion.positional = [
          [
            "list"
            "clear"
          ]
        ];
      }
    ];
  };
}
