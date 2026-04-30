{ ... }:
{
  flake.modules.homeManager.easyeffects = { ... }: {
    services.easyeffects.enable = true;
    home.file.".local/share/easyeffects/input/rnnoise.json".text = builtins.toJSON {
      input = {
        blocklist = [ ];
        plugins_order = [ "rnnoise#0" ];
        "rnnoise#0" = {
          bypass = false;
          enable-vad = true;
          input-gain = 0.0;
          model-path = "";
          output-gain = 0.0;
          release = 20.0;
          vad-thres = 70.0;
          wet = 0.0;
        };
      };
    };
  };
}
