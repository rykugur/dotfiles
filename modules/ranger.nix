{ self, ... }:
{
  flake.nixosModules.ranger =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.ranger ];
    };

  flake.homeModules.ranger =
    { ... }:
    {
      programs.ranger = {
        enable = true;
        plugins = [
          {
            name = "ranger-devicons";
            src = fetchGit {
              url = "https://github.com/cdump/ranger-devicons2";
              rev = "94bdcc19218681debb252475fd9d11cfd274d9b1";
            };
          }
          {
            name = "zoxide";
            src = fetchGit {
              url = "https://github.com/jchook/ranger-zoxide.git";
              rev = "363df97af34c96ea873c5b13b035413f56b12ead";
            };
          }
        ];
      };
    };
}
