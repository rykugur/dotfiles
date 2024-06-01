{inputs, ...}: let
  swayfx = inputs.swayfx.packages.x86_64-linux.default;
in {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = swayfx;
  };
}
