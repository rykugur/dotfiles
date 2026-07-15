{ ... }:
{
  flake.modules.homeManager.easyeffects =
    { ... }:
    {
      services.easyeffects.enable = true;

      # DeepFilterNet (deep noise suppression) -> Gate. Denoise the TV out from
      # under speech, then gate the residual so Discord's VAD sees silence in
      # the gaps. Keys/defaults are EasyEffects 8.2.5's; only attack/release/
      # curve-threshold/reduction are tuned from default.
      home.file.".local/share/easyeffects/input/mic-chain.json".text = builtins.toJSON {
        input = {
          blocklist = [ ];
          plugins_order = [ "deepfilternet#0" "gate#0" ];
          "deepfilternet#0" = {
            bypass = false;
            input-gain = 0.0;
            output-gain = 0.0;
            attenuation-limit = 100.0;
            min-processing-threshold = -10.0;
            max-erb-processing-threshold = 30.0;
            max-df-processing-threshold = 20.0;
            min-processing-buffer = 0;
            post-filter-beta = 0.02;
          };
          "gate#0" = {
            bypass = false;
            input-gain = 0.0;
            output-gain = 0.0;
            dry = -80.01;
            wet = 0.0;
            attack = 2.0;
            release = 200.0;
            curve-threshold = -40.0;
            curve-zone = -6.0;
            hysteresis = false;
            hysteresis-threshold = -12.0;
            hysteresis-zone = -6.0;
            reduction = -60.0;
            makeup = 0.0;
            stereo-split = false;
            sidechain = {
              type = "Internal";
              mode = "Peak";
              source = "Middle";
              stereo-split-source = "Left/Right";
              preamp = 0.0;
              reactivity = 10.0;
              lookahead = 0.0;
            };
            hpf-mode = "Off";
            hpf-frequency = 10.0;
            lpf-mode = "Off";
            lpf-frequency = 20000.0;
            input-to-sidechain = -80.01;
            input-to-link = -80.01;
            sidechain-to-input = -80.01;
            sidechain-to-link = -80.01;
            link-to-input = -80.01;
            link-to-sidechain = -80.01;
          };
        };
      };
    };
}
