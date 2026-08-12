{ inputs, self, ... }:
{
  flake.modules.nixos.dank-material-shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.dankMaterialShell;
      username = config.ryk.username;
      coreutils = "${pkgs.coreutils}/bin";
      grep = "${pkgs.gnugrep}/bin/grep";
      sed = "${pkgs.gnused}/bin/sed";
    in
    {
      options.ryk.dankMaterialShell = {
        enable = lib.mkEnableOption "the dankMaterialShell quickshell bar";

        screenshotBackend = lib.mkOption {
          type = lib.types.enum [
            "swappy"
            "satty"
            "none"
          ];
          default = "none";
        };

        avatar = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = ./avatar.png;
          description = "Avatar image to expose to DMS through AccountsService.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.accounts-daemon.enable = lib.mkIf (cfg.avatar != null) true;

        systemd.user.services.niri-flake-polkit.enable = false;
        security.pam.services."dankshell-u2f".text = ''
          auth     required ${pkgs.pam_u2f}/lib/security/pam_u2f.so cue
          account  required pam_permit.so
          password required pam_deny.so
          session  required pam_permit.so
        '';

        system.activationScripts.dankMaterialShellAvatar = lib.mkIf (cfg.avatar != null) (
          lib.concatStringsSep "\n" [
            "${coreutils}/install -D -m 0644 ${cfg.avatar} /var/lib/AccountsService/icons/${username}"
            "${coreutils}/install -d -m 0755 /var/lib/AccountsService/users"
            ""
            "user_file=/var/lib/AccountsService/users/${username}"
            "icon_line=Icon=/var/lib/AccountsService/icons/${username}"
            ""
            ''if [ -f "$user_file" ]; then''
            ''if ${grep} -q '^Icon=' "$user_file"; then''
            ''${sed} -i "s|^Icon=.*|$icon_line|" "$user_file"''
            ''elif ${grep} -q '^\[User\]' "$user_file"; then''
            ''${sed} -i "/^\[User\]/a $icon_line" "$user_file"''
            "  else"
            ''printf '\n[User]\n%s\n' "$icon_line" >> "$user_file"''
            "  fi"
            "else"
            ''printf '[User]\n%s\n' "$icon_line" > "$user_file"''
            "fi"
            ""
            ''${coreutils}/chmod 0600 "$user_file"''
            ""
          ]
        );

        home-manager.users.${username}.imports = [ self.modules.homeManager.dank-material-shell ];
      };
    };

  flake.modules.homeManager.dank-material-shell =
    {
      config,
      lib,
      nixosConfig,
      pkgs,
      ...
    }:
    let
      rykCfg = nixosConfig.ryk;
      screenshotEditor = rykCfg.dankMaterialShell.screenshotBackend;
      # Only the active compositor's integration is declared; the other
      # compositor's home-manager options may not even exist on this host.
      isNiri = rykCfg.desktop.compositor == "niri";
      isHyprland = rykCfg.desktop.compositor == "hyprland";
    in
    {
      imports = [
        inputs.dankMaterialShell.homeModules.dank-material-shell
      ]
      ++ lib.optionals isNiri [ inputs.dankMaterialShell.homeModules.niri ];

      config = lib.mkMerge [
        {
          home.packages =
            lib.optionals (screenshotEditor == "swappy") [ pkgs.swappy ]
            ++ lib.optionals (screenshotEditor == "satty") [ pkgs.satty ];

          programs.dank-material-shell = {
            enable = true;

            systemd.enable = false;

            enableAudioWavelength = true;
            enableCalendarEvents = false;
            enableDynamicTheming = false;
            enableSystemMonitoring = true;

            settings = {
              # SettingsSpec.js: https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/refs/heads/master/quickshell/Common/settings/SettingsSpec.js
              # SessionSpec.js: https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/refs/heads/master/quickshell/Common/settings/SessionSpec.js
              dynamicThemeing = false;
              enableU2f = true;

              acMonitorTimeout = 900; # 15 min
              acLockTimeout = 1800; # 30 min
              acSuspendTimeout = 3600; # 60 min
              lockBeforeSuspend = true;

              showWeather = true;
              useFahrenheit = true;
              weatherLocation = "Rosemount, MN";
              weatherCoordinates = "44.747998,-93.133574";
            };
          };
        }

        (lib.optionalAttrs isNiri {
          # Declared by inputs.dankMaterialShell.homeModules.niri, imported above
          # only when niri is the active compositor.
          programs.dank-material-shell.niri = {
            enableKeybinds = false;
            enableSpawn = false;

            # shit breaks with this enabled.
            # more info here: https://danklinux.com/docs/dankmaterialshell/nixos-flake#config-includes
            includes.enable = false;
          };

          programs.niri.settings = {
            environment = lib.mkIf (screenshotEditor != "none") {
              DMS_SCREENSHOT_EDITOR = screenshotEditor;
            };

            binds =
              with config.lib.niri.actions;
              let
                spawnAction =
                  actions:
                  spawn (
                    [
                      "dms"
                      "ipc"
                      "call"
                    ]
                    ++ actions
                  );
                launcherAction = spawnAction [
                  "spotlight"
                  "toggle"
                ];
              in
              {
                "Mod+Print".action = spawn [
                  "dms"
                  "screenshot"
                  "--no-file"
                ];
                "Mod+Shift+Print".action = spawn [
                  "dms"
                  "ipc"
                  "call"
                  "niri"
                  "screenshot"
                ];
                # "Mod+Shift+Print".action = spawn [ "dms" "screenshot" "--no-file" ];
                "Mod+Shift+e".action = spawnAction [
                  "powermenu"
                  "toggle"
                ];
                "Mod+Shift+v".action = spawnAction [
                  "clipboard"
                  "toggle"
                ];
                "Mod+0".action = spawnAction [
                  "notepad"
                  "toggle"
                ];

                "Mod+r".action = launcherAction;
                "Mod+Space".action = launcherAction;
              }
              // {
                XF86AudioLowerVolume.action = spawnAction [
                  "audio"
                  "decrement"
                  "5"
                ];
                XF86AudioRaiseVolume.action = spawnAction [
                  "audio"
                  "increment"
                  "5"
                ];
                XF86AudioMute.action = spawnAction [
                  "audio"
                  "mute"
                ];
                XF86Tools.action = spawnAction [
                  "audio"
                  "micmute"
                ];
                XF86AudioPlay.action = spawnAction [
                  "mpris"
                  "playPause"
                ];
                XF86AudioPause.action = spawnAction [
                  "mpris"
                  "playPause"
                ];
                XF86AudioNext.action = spawnAction [
                  "mpris"
                  "next"
                ];
                XF86AudioPrev.action = spawnAction [
                  "mpris"
                  "previous"
                ];
                XF86MonBrightnessDown.action = spawnAction [
                  "brightness"
                  "decrement"
                  "5"
                ];
                XF86MonBrightnessUp.action = spawnAction [
                  "brightness"
                  "increment"
                  "5"
                ];
              };

            spawn-at-startup = [
              {
                argv = [
                  "dms"
                  "run"
                ];
              }
            ];
          };
        })

        (lib.optionalAttrs isHyprland {
          wayland.windowManager.hyprland.settings = {
            bind =
              let
                dmsIpc = action: "dms ipc call ${action}";
                audioIpc = action: "dms ipc call audio ${action}";
                mprisIpc = action: "dms ipc call mpris ${action}";
                launcher = dmsIpc "spotlight toggle";
              in
              [
                "$mainMod SHIFT, E, exec, ${dmsIpc "powermenu toggle"}"
                "$mainMod, R, exec, ${launcher}"
                "$mainMod, space, exec, ${launcher}"
                "$mainMod, 0, exec, ${dmsIpc "notepad toggle"}"

                ", XF86AudioMute, exec, ${audioIpc "mute"}"
                ", XF86AudioPlay, exec, ${audioIpc "playPause"}"
                ", XF86AudioPause, exec, ${audioIpc "playPause"}"
                ", XF86AudioNext, exec, ${mprisIpc "next"}"
                ", XF86AudioPrev, exec, ${mprisIpc "previous"}"
                ", XF86MonBrightnessUp, exec, ${dmsIpc "brightness increment 5"}"
                ", XF86MonBrightnessDown, exec, ${dmsIpc "brightness decrement 5"}"
              ];
            exec-once = [ "dms run" ];
          };
        })
      ];
    };
}
