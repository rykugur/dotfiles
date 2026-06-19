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
      # This only loads the kernel driver (exposes /dev/ntsync); apps opt in at
      # runtime via WINENTSYNC=1 (Proton sets it automatically; for the lug-wine SC
      # runner it's exported in sc-launch.sh). Mainlined as a module in kernel 6.14;
      # skipped on older kernels.
      boot.kernelModules = lib.optional (
        lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14"
      ) "ntsync";
    };
}
