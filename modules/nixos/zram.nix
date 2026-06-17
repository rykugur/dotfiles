{ ... }:
{
  flake.modules.nixos.zram =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.ryk.zram;
    in
    {
      options.ryk.zram = {
        memoryPercent = lib.mkOption {
          type = lib.types.ints.between 1 100;
          default = 25;
          description = ''
            Percentage of RAM to allocate to the zram swap device.

            LUG performance-tuning guidance (zram-size):
              - 16GB RAM: 100 (ram)
              - 32GB RAM: 100 (ram)
              - 64GB RAM:  25 (ram / 4)
          '';
        };

        algorithm = lib.mkOption {
          type = lib.types.str;
          default = "zstd";
          description = "Compression algorithm for the zram device.";
        };

        swapfileSize = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 8 * 1024;
          description = ''
            Backing swapfile size in MiB. Acts as overflow when zram is full.
            Set to 0 to skip the swapfile entirely.
          '';
        };
      };

      config = {
        zramSwap = {
          enable = true;
          memoryPercent = cfg.memoryPercent;
          algorithm = cfg.algorithm;
        };

        swapDevices = lib.optionals (cfg.swapfileSize > 0) [
          {
            device = "/swapfile";
            size = cfg.swapfileSize;
          }
        ];

        # zswap must be disabled when using zram (LUG).
        boot.kernelParams = [ "zswap.enabled=0" ];
      };
    };
}
