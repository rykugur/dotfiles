{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen-lite =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.ryk.username;
    in
    {
      # LUG prereqs — https://wiki.starcitizen-lug.org/Alternative-Installations
      # Values match nix-citizen's (which exceed the LUG floor of 1048576 / 524288).
      boot.kernel.sysctl = {
        "vm.max_map_count" = lib.mkOverride 999 16777216;
        "fs.file-max" = lib.mkOverride 999 524288;
      };

      security.pam.loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "16777216";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "16777216";
        }
      ];

      # Kernel modules nix-citizen sets up for SC's audio/video pipeline.
      # (ntsync moved to its own module — it's a general wine/Proton feature, not SC's.)
      boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      boot.kernelModules = [ "snd-aloop" ];

      services.udev = {
        enable = true;
        extraRules = ''
          # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
          KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
        '';
      };

      nix.settings = {
        substituters = [
          "https://nix-citizen.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen-lite ];
    };

  flake.modules.homeManager.starcitizen-lite =
    { pkgs, ... }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      gameglass = inputs.nix-citizen.packages.${sys}.gameglass;
      lug-helper = inputs.nix-citizen.packages.${sys}.lug-helper;
    in
    {
      home.packages = with pkgs; [
        opentrack
        gameglass
        lug-helper
      ];

      # LUG pre-launch / post-exit scripts for head tracking. sc-launch.sh has a
      # manually-added hook (see the wiki Tips-and-Tricks) that runs these INSIDE its
      # steam-run sandbox, so opentrack's FreeTrack bridge shares the game's wineserver
      # — two separate steam-runs get private /tmp dirs hence two wineservers, and the
      # tracking shared memory never crosses (the bug we chased for ages).
      #
      # They live in ~/.config/star-citizen, NOT the prefix: the LUG Helper refuses to
      # install SC if ~/Games/star-citizen already exists, so home-manager must not
      # pre-create it. Embedding ${pkgs.opentrack} keeps the path current across updates.
      #
      # Launch via the stock lug "RSI Launcher" entry; opentrack comes up with the game
      # (configure its Wine output + Start, or enable opentrack's auto-start-tracking for
      # hands-off) and is killed on exit. Cursor confinement stays the in-prefix
      # UseTakeFocus=N registry key + in-game Borderless.
      xdg.configFile = {
        "star-citizen/sc-prelaunch.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            ${pkgs.opentrack}/bin/opentrack &
            echo $! > /tmp/sc-opentrack.pid
          '';
        };
        "star-citizen/sc-postexit.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            kill "$(cat /tmp/sc-opentrack.pid 2>/dev/null)" 2>/dev/null || true
          '';
        };
      };

      xdg.desktopEntries.gameglass = {
        name = "GameGlass";
        icon = "gameglass";
        exec = "${gameglass}/bin/gameglass";
        terminal = false;
        type = "Application";
        categories = [
          "Game"
          "Utility"
        ];
      };
    };
}
