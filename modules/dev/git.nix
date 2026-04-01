{ ... }:
{
  flake.modules.homeManager.git =
    { config, lib, ... }:
    {
      programs = {
        git = {
          enable = true;

          signing.format = null;

          settings = {
            user = {
              name = "Dusty";
              email = "rollhax@gmail.com";
            };
          };

          lfs = { enable = true; };
        };

        diff-so-fancy = {
          enable = true;
          enableGitIntegration = true;
        };

        gh = {
          enable = true;
          settings = { git_protocol = "ssh"; };
        };

      };

      home.file.".gitconfig" = { source = ../../configs/gitconfig; };
    };
}
