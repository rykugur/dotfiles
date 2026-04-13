{ ... }:
{
  flake.modules.homeManager.easyeffects = { ... }: {
    services.easyeffects.enable = true;
    home.file.".config/easyeffects/input/rnnoise.json".text = builtins.toJSON {
      input = {
        blocklist = [ ];
        plugins_order = [ "rnnoise" ];
        rnnoise = {
          input-gain = 0.0;
          model-path = "";
          output-gain = 0.0;
        };
      };
    };
  };
}
