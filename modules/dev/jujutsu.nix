{ ... }:
{
  flake.modules.homeManager.jujutsu =
    { ... }:
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          ui = { default-command = "status"; };
          user = {
            name = "Dusty";
            email = "dusty@ryk.sh";
          };
          signing = {
            behavior = "own";
            backend = "ssh";
            key = "~/.ssh/id_ed25519.pub";
          };

          # Move the bookmark along with each `jj commit`/`jj new`, so pushing
          # is just `jj git push` instead of moving the bookmark by hand first.
          # Applies to whichever bookmark sits at the new commit's parent; add
          # names to disabled-branches to hold one still (e.g. a shared trunk).
          experimental-advance-branches = {
            enabled-branches = [ "glob:*" ];
            disabled-branches = [ ];
          };

          # Escape hatch for bookmarks left behind: move the nearest one
          # backwards-or-forwards onto @-.
          aliases.tug = [
            "bookmark"
            "move"
            "--from"
            "heads(::@- & bookmarks())"
            "--to"
            "@-"
          ];
        };
      };
    };
}
