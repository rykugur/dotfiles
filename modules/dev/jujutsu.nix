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
        };
      };
    };
}
