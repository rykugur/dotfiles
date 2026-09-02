{ ... }:
{
  flake.modules.homeManager.git =
    { ... }:
    {
      programs = {
        git = {
          enable = true;

          signing = {
            key = "~/.ssh/id_ed25519";
            format = "ssh";
          };

          settings = {
            alias = {
              back = "reset HEAD~1";
              undo = "reset --soft HEAD^";
            };

            commit.gpgSign = true;

            user = {
              name = "Dusty";
              email = "rollhax@gmail.com";
            };
          };

          lfs = {
            enable = true;
          };
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
        };

        gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
          };
        };
      };
    };
}
