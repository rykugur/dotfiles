{ ... }:
{
  flake.modules.homeManager.easyeffects = { ... }: {
    services.easyeffects.enable = true;
    home.file = {
      ".config/easyeffects/input/input.json".source =
        ../../configs/easyeffects/input/improved-microphone-male-voices.json;
      ".config/easyeffects/output/output.json".source =
        ../../configs/easyeffects/output/heavy-bass.json;
    };
  };
}
