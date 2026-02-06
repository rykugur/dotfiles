{ self, ... }:
{
  flake.nixosModules.jujutsu =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.jujutsu ];
    };

  flake.homeModules.jujutsu =
    { ... }:
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          ui = {
            default-command = "status";
          };
          user = {
            name = "rykugur";
            email = "rollhax@gmail.com";
          };
        };
      };
    };
}
