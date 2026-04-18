{ ... }:
{
  flake.modules.homeManager.sesh =
    { ... }:
    {
      # Required to satisfy the tmux integration assertion
      programs.fzf.tmux.enableShellIntegration = true;

      programs.sesh = {
        enable = true;
        icons = true;
        enableTmuxIntegration = true;
      };
    };
}
