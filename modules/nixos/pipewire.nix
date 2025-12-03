{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.pipewire;
in {
  # imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];

  options.rhx.pipewire = {
    enable = lib.mkEnableOption "Enable pipewire nixOS module";

    rate = lib.mkOption {
      type = lib.types.number;
      default = 48000;
    };

    quantum = lib.mkOption {
      type = lib.types.number;
      default = 32;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.pulseaudio
      pkgs.alsa-utils # for amixer
      pkgs.faudio
    ];

    services = {
      pipewire = {
        enable = true;
        # alsa is not required but helpful for 32 bit apps, particularly older games
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;

        extraConfig = let
          rate = builtins.toString config.rhx.pipewire.rate;
          quantum = builtins.toString config.rhx.pipewire.quantum;
        in {
          pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = rate;
              "default.clock.quantum" = quantum;
              "default.clock.min-quantum" = quantum;
              "default.clock.max-quantum" = quantum;
            };
          };
          pipewire-pulse."92-low-latency" =
            let quantumOverRate = "${quantum}/${rate}";
            in {
              "context.properties" = [{
                name = "libpipewire-module-protocol-pulse";
                args = { };
              }];
              "pulse.properties" = {
                "pulse.min.req" = quantumOverRate;
                "pulse.default.req" = quantumOverRate;
                "pulse.max.req" = quantumOverRate;
                "pulse.min.quantum" = quantumOverRate;
                "pulse.max.quantum" = quantumOverRate;
              };
              "stream.properties" = {
                "node.latency" = quantumOverRate;
                "resample.quality" = 1;
              };
            };
        };

        # lowLatency = {
        #   enable = true;
        #   quantum = 2048;
        #   rate = 48000;
        # };
      };
    };

    # make pipewire realtime-capable
    security.rtkit.enable = true;

    users.users.${username}.extraGroups = [ "audio" ];
  };
}
