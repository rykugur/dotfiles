{ self, ... }:
{
  flake.nixosModules.easyeffects =
    { config, ... }:
    {
      home-managers.users.${config.meta.ryk.username}.imports = [ self.homeModules.easyeffects ];
    };

  flake.homeModules.easyeffects =
    { ... }:
    {
      services.easyeffects = {
        enable = true;
      };

      home.file = {
        ".config/easyeffects/input/input.json".source =
          ../../configs/easyeffects/input/improved-microphone-male-voices.json;
        ".config/easyeffects/output/output.json".source = ../../configs/easyeffects/output/heavy-bass.json;
      };
    };
}
