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
            name = "rykugur";
            email = "rollhax@gmail.com";
          };
        };
      };
    };
}
