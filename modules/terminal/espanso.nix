{ ... }:
{
  flake.modules.homeManager.espanso =
    { ... }:
    {
      services.espanso = {
        enable = true;

        matches = {
          default = {
            matches = [
              {
                trigger = ":install-helix";
                replace = "curl -fsSL s.ryk.sh/install-helix-deb | bash -s --";
              }
            ];
          };
        };
      };
    };
}
