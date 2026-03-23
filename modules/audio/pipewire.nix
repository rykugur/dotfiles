{ ... }:
{
  flake.modules.nixos.pipewire =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ryk.pipewire;
      nsCfg = cfg.noiseSuppression;
    in
    {
      options.ryk.pipewire = {
        rate = lib.mkOption {
          type = lib.types.number;
          default = 48000;
        };
        quantum = lib.mkOption {
          type = lib.types.number;
          default = 32;
        };

        noiseSuppression = {
          enable = lib.mkEnableOption "mic noise suppression via rnnoise filter-chain";
          vadThreshold = lib.mkOption {
            type = lib.types.number;
            default = 50.0;
            description = "VAD threshold (0–100). Higher = less sensitive.";
          };
          vadGracePeriod = lib.mkOption {
            type = lib.types.number;
            default = 200;
            description = "ms to keep audio open after voice drops below threshold.";
          };
        };
      };

      config = {
        environment.systemPackages = with pkgs;
          [ pulseaudio alsa-utils faudio ]
          ++ lib.optionals nsCfg.enable [ rnnoise-plugin ];

        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          pulse.enable = true;

          extraConfig =
            let
              rate = builtins.toString cfg.rate;
              quantum = builtins.toString cfg.quantum;
              qor = "${quantum}/${rate}";
            in
            {
              pipewire = {
                "92-low-latency"."context.properties" = {
                  "default.clock.rate" = rate;
                  "default.clock.quantum" = quantum;
                  "default.clock.min-quantum" = quantum;
                  "default.clock.max-quantum" = quantum;
                };
              } // lib.optionalAttrs nsCfg.enable {
                "99-input-denoising"."context.modules" = [
                  {
                    name = "libpipewire-module-filter-chain";
                    args = {
                      "node.description" = "Noise Canceling Source";
                      "media.name" = "Noise Canceling Source";
                      "filter.graph" = {
                        nodes = [
                          {
                            type = "ladspa";
                            name = "rnnoise";
                            plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                            label = "noise_suppressor_mono";
                            control = {
                              "VAD Threshold (%)" = nsCfg.vadThreshold;
                              "VAD Grace Period (ms)" = nsCfg.vadGracePeriod;
                              "Retroactive VAD Grace (ms)" = 0;
                            };
                          }
                        ];
                      };
                      "capture.props" = {
                        "node.name" = "capture.rnnoise_source";
                        "node.passive" = true;
                        "audio.rate" = cfg.rate;
                        "audio.channels" = 1;
                        "audio.position" = [ "MONO" ];
                      };
                      "playback.props" = {
                        "node.name" = "rnnoise_source";
                        "media.class" = "Audio/Source/Virtual";
                        "audio.rate" = cfg.rate;
                        "audio.channels" = 1;
                        "audio.position" = [ "MONO" ];
                      };
                    };
                  }
                ];
              };

              pipewire-pulse."92-low-latency" = {
                "context.properties" = [
                  {
                    name = "libpipewire-module-protocol-pulse";
                    args = { };
                  }
                ];
                "pulse.properties" = {
                  "pulse.min.req" = qor;
                  "pulse.default.req" = qor;
                  "pulse.max.req" = qor;
                  "pulse.min.quantum" = qor;
                  "pulse.max.quantum" = qor;
                };
                "stream.properties" = {
                  "node.latency" = qor;
                  "resample.quality" = 1;
                };
              };
            };
        };

        security.rtkit.enable = true;
        users.users.${config.ryk.username}.extraGroups = [ "audio" ];
      };
    };
}
