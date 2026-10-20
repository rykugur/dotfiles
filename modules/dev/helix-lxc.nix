{ ... }:
{
  # Helix adjustments for headless containers. Import alongside the shared
  # `helix` module on any host without a Wayland session.
  flake.modules.homeManager.helix-lxc =
    { lib, ... }:
    {
      # wl-copy does not exist here; fall back to OSC 52 through the terminal.
      programs.helix.settings.editor.clipboard-provider = lib.mkForce "termcode";
      # Television's fuzzy matcher crashes while typing in an LXC.
      programs.helix.settings.keys.normal.space.f = lib.mkForce "file_picker";
    };
}
