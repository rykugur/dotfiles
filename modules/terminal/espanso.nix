{ ... }:
{
  flake.modules.homeManager.espanso =
    { ... }:
    {
      services.espanso = {
        enable = true;

        configs = {
          default = {
            show_notifications = false;
            show_icon = false;
          };
        };

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
