{ ... }:
{
  # VIRPIL Controls flight gear (VID 3344). Pulled in via the nixos.gaming group
  # (modules/groups/gaming.nix) so it's available for any space sim, not tied to a
  # single game module — keeps the raw-HID rule + joystick diagnostics in one place.
  flake.modules.nixos.virpil =
    { pkgs, ... }:
    {
      services.udev = {
        enable = true;
        extraRules = ''
          # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
          KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
        '';
      };

      # Joystick diagnostics — evtest reads /dev/input/eventN (raw axes/buttons,
      # shows idle/min/max), linuxConsoleTools provides jstest/jscal. Handy for
      # debugging stuck inputs (e.g. an analog axis bound to a digital action
      # latching, like spacebrake-on-a-slider).
      environment.systemPackages = with pkgs; [
        evtest
        linuxConsoleTools
      ];
    };
}
