{ self, ... }:
{
  flake.modules.nixos.viture =
    { config, pkgs, ... }:
    let
      username = config.ryk.username;
    in
    {
      # Allow the user session to talk to VITURE One USB IMU without root.
      # Vendor ID sourced from upstream (hodasemi/xr_to_opentrack_rs, src/hotplug/viture_hotplug.rs).
      services.udev = {
        enable = true;
        packages = [ pkgs.libusb1 ];
        extraRules = ''
          SUBSYSTEM=="usb", ATTRS{idVendor}=="35ca", MODE="0660", TAG+="uaccess"
        '';
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.viture ];
    };

  flake.modules.homeManager.viture =
    { pkgs, ... }:
    let
      mkLauncher = { name, opentrack }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ pkgs.xr-to-opentrack ];
          text = ''
            # Start the VITURE IMU bridge in the background, then run opentrack
            # in the foreground. Trap EXIT so closing opentrack (or any non-SIGKILL
            # death) tears the bridge down too.
            xr_to_opentrack_rs &
            sidecar=$!
            trap 'kill "$sidecar" 2>/dev/null || true' EXIT
            exec ${opentrack}/bin/opentrack "$@"
          '';
        };

      opentrack-xr-run = mkLauncher {
        name = "opentrack-xr-run";
        opentrack = pkgs.opentrack-xr;
      };

      opentrack-StarCitizen-xr-run = mkLauncher {
        name = "opentrack-StarCitizen-xr-run";
        opentrack = pkgs.opentrack-StarCitizen-xr;
      };
    in
    {
      # xr-to-opentrack is on PATH for direct invocation (e.g. `xr_to_opentrack_rs --center`
      # while opentrack is already running). Slim opentrack variants are NOT added
      # here — they'd collide with pkgs.opentrack on bin/opentrack. They're reached
      # via the launcher scripts above, which embed them by store path.
      home.packages = [
        pkgs.xr-to-opentrack
        opentrack-xr-run
        opentrack-StarCitizen-xr-run
      ];

      xdg.desktopEntries.opentrack-xr = {
        name = "OpenTrack (XR)";
        exec = "opentrack-xr-run";
        terminal = false;
        type = "Application";
        categories = [ "Utility" ];
        genericName = "Head tracking (VITURE One)";
      };

      xdg.desktopEntries.opentrack-StarCitizen-xr = {
        name = "OpenTrack StarCitizen (XR)";
        exec = "opentrack-StarCitizen-xr-run";
        terminal = false;
        type = "Application";
        categories = [
          "Utility"
          "Game"
        ];
        genericName = "Head tracking (VITURE One, Star Citizen build)";
      };
    };
}
