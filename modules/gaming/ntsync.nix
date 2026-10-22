{ ... }:
{
  flake.modules.nixos.ntsync =
    {
      config,
      lib,
      ...
    }:
    {
      # In-kernel NT synchronization for wine/Proton — the modern, faster, more
      # correct replacement for esync/fsync. Benefits ANY wine game (Steam/Proton,
      # Lutris, lug-wine, EVE, …), so it lives in its own module rather than riding
      # along in a single game's config.
      #
      # Loading the driver exposes /dev/ntsync; Wine 11 uses it when
      # available. Proton has its own PROTON_USE_NTSYNC switch (set in
      # Jezrien's user session). Keep this separate from SC so other Wine
      # games can use the same driver.
      boot.kernelModules = lib.optional (
        lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14"
      ) "ntsync";
    };
}
