{ self, ... }:
{
  flake.nixosModules.git =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.git ];
    };

  flake.homeModules.git =
    { ... }:
    {
      programs = {
        git = {
          enable = true;

          settings = {
            user = {
              name = "Dusty";
              email = "rollhax@gmail.com";
            };
          };

          lfs = {
            enable = true;
          };
        };

        diff-so-fancy = {
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

      home.file.".gitconfig" = {
        source = ../configs/gitconfig;
      };
    };
}
