{ ... }:
{
  flake.modules.nixos.vasher-prebuild =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ryk.vasherPrebuild;
      runtime = pkgs.writeTextFile {
        name = "vasher-prebuild.sh";
        executable = true;
        text = builtins.readFile ./vasher-prebuild.sh;
      };
      dashboard = pkgs.buildNpmPackage {
        pname = "vasher-dashboard";
        version = "1.0.0";
        src = ./vasher-dashboard;
        npmDepsHash = "sha256-Lt2zzqo4LIbO93T7XZbVAVJ9/foyXopE5wpIixxVmjM=";
        npmBuildScript = "build";
        installPhase = ''
          mkdir -p "$out/share/vasher-dashboard"
          cp -r dist/. "$out/share/vasher-dashboard/"
        '';
      };
      prebuild = pkgs.writeShellApplication {
        name = "vasher-prebuild";
        runtimeInputs = with pkgs; [
          bash
          coreutils
          git
          jq
          nix
          openssh
          util-linux
        ];
        text = ''
          export REPO_URL=${lib.escapeShellArg cfg.repoUrl}
          export TARGET_ATTR=${lib.escapeShellArg cfg.targetAttr}
          export CACHE_BRANCH=${lib.escapeShellArg cfg.cacheBranch}
          export KEEP_ROOTS=${lib.escapeShellArg (toString cfg.keepRoots)}
          export EXCLUDED_PACKAGES=${lib.escapeShellArg (builtins.toJSON cfg.excludedPackages)}
          export GITHUB_TOKEN_FILE=${lib.escapeShellArg config.sops.secrets."swoleflake/github_token".path}
          exec ${pkgs.bash}/bin/bash ${runtime} "$@"
        '';
      };
      monitor = pkgs.writers.writePython3Bin "vasher-prebuild-monitor" {
        flakeIgnore = [ "E203" "E265" "E501" "W503" ];
      } (builtins.readFile ./vasher-prebuild-monitor.py);
      agent = pkgs.writers.writePython3Bin "vasher-agent-verb" {
        flakeIgnore = [ "E203" "E265" "E501" "W503" ];
      } (builtins.readFile ./vasher-agent-verb.py);

      retry = pkgs.writeShellApplication {
        name = "vasher-prebuild-retry";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          request=/var/lib/vasher/agent/retry.json
          base=$(jq -er '.baseRevision | select(test("^[0-9a-f]{40}$"))' "$request")
          revision=$(jq -er '.revision | select(test("^[0-9a-f]{40}$"))' "$request")
          exec ${prebuild}/bin/vasher-prebuild retry "$base" "$revision"
        '';
      };
      serviceConfig = {
        Type = "oneshot";
        User = "vasher";
        Group = "vasher";
        WorkingDirectory = "/var/lib/vasher";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ "/var/lib/vasher" "/nix/var/nix" ];
        # nix has intermittently segfaulted under this LXC; without this, each
        # crash leaves a 100-350MB core dump in WorkingDirectory (cwd), and
        # nothing ever cleans them up. 369 accumulated dumps filled the disk
        # to 100% on 2026-09-11 and starved the flake-lock write itself.
        LimitCORE = 0;
      };
      environment = {
        HOME = "/var/lib/vasher";
        GIT_SSH_COMMAND = "ssh -i /run/secrets/swoleflake/deploy_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new";
      };
      service = mode: {
        description = "Prebuild Jezrien closure from ${mode}";
        serviceConfig = serviceConfig // {
          ExecStart = "${prebuild}/bin/vasher-prebuild ${mode}";
        };
        inherit environment;
      };
    in
    {
      options.ryk.vasherPrebuild = {
        repoUrl = lib.mkOption {
          type = lib.types.str;
          default = "git@github.com:rykugur/dotfiles.git";
        };
        targetAttr = lib.mkOption {
          type = lib.types.str;
          default = "nixosConfigurations.jezrien.config.system.build.toplevel";
        };
        excludedPackages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Package names intentionally excluded from the prebuilt closure.";
        };
        cacheBranch = lib.mkOption {
          type = lib.types.str;
          default = "cache-bump";
        };
        keepRoots = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "Number of successful Jezrien closures to retain as GC roots. 1 keeps only the latest candidate.";
        };
        agentKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Public keys allowed to drive the typed agent action channel. Each key is forced to the channel program and nothing else.";
        };
      };

      config = {
        sops.secrets."swoleflake/deploy_key" = {
          key = "swoleflake/deploy_key";
          owner = "vasher";
          group = "vasher";
          mode = "0400";
        };
        sops.secrets."swoleflake/github_token" = {
          key = "swoleflake/github_token";
          owner = "vasher";
          group = "vasher";
          mode = "0400";
        };
        sops.secrets."swoleflake/openrouter_api_key" = {
          key = "swoleflake/openrouter_api_key";
          owner = "root";
          group = "root";
          mode = "0400";
        };

        systemd.services = {
          vasher-prebuild-refresh = service "refresh";
          vasher-prebuild-candidate = service "candidate";
          vasher-prebuild-narrow = service "narrow";
          vasher-prebuild-cleanup = service "cleanup" // {
            description = "Collect garbage before a Vasher prebuild retry";
            serviceConfig = serviceConfig // {
              ExecStart = "${pkgs.nix}/bin/nix-collect-garbage";
            };
          };
          vasher-prebuild-retry = service "retry" // {
            description = "Retry the recorded Vasher candidate";
            serviceConfig = serviceConfig // {
              ExecStart = "${retry}/bin/vasher-prebuild-retry";
            };
          };
          vasher-prebuild-monitor = {
            description = "Monitor Vasher prebuild resource safety";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            environment = {
              OPENROUTER_API_KEY_FILE = config.sops.secrets."swoleflake/openrouter_api_key".path;
            };
            serviceConfig = {
              Type = "simple";
              ExecStart = "${monitor}/bin/vasher-prebuild-monitor";
              Restart = "always";
              RestartSec = "10s";
              User = "root";
              Group = "vasher";
              UMask = "0077";
              NoNewPrivileges = true;
              PrivateDevices = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectSystem = "strict";
              ProtectControlGroups = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              RestrictRealtime = true;
              CapabilityBoundingSet = "";
              ReadWritePaths = [
                "/var/lib/vasher/dashboard"
                "/var/lib/vasher/monitor"
                # The monitor writes its own retry request here, beside the
                # channel's.
                "/var/lib/vasher/agent"
              ];
              ReadOnlyPaths = [
                config.sops.secrets."swoleflake/openrouter_api_key".path
              ];
              InaccessiblePaths = [
                "/home"
                "/root/.ssh"
                config.sops.secrets."swoleflake/deploy_key".path
                config.sops.secrets."swoleflake/github_token".path
                "/run/current-system/sw/bin/ssh"
                "/run/current-system/sw/bin/scp"
                "/run/current-system/sw/bin/sftp"
                "/run/current-system/sw/bin/ssh-add"
                "/run/current-system/sw/bin/ssh-agent"
              ];
              IPAddressDeny = [
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
                "169.254.0.0/16"
                "fc00::/7"
                "fe80::/10"
              ];
            };
          };
        };

        systemd.timers.vasher-prebuild-refresh = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5m";
            OnUnitInactiveSec = "15m";
            Persistent = true;
          };
        };
        systemd.timers.vasher-prebuild-candidate = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 03:00:00";
            Persistent = true;
            RandomizedDelaySec = "10m";
          };
        };
        # The channel user writes nothing outside /var/lib/vasher/agent, so the
        # dashboard and monitor directories keep their original ownership and
        # mode. Directory write permission is the permission to unlink, and the
        # storage fault record must stay out of the channel's reach.
        systemd.tmpfiles.rules = [
          "d /var/lib/vasher/dashboard 0775 vasher vasher -"
          "d /var/lib/vasher/monitor 0755 root root -"
          "d /var/lib/vasher/agent 0755 vasher-agent vasher-agent -"
          "f /var/lib/vasher/dashboard/events.json 0644 root root - []"
        ];

        # One entry is one authorized_keys line. An embedded newline would
        # start a second line with neither the forced command nor restrict,
        # which is an interactive shell for the channel key.
        assertions = [
          {
            assertion = !(lib.any (key: lib.hasInfix "\n" key || lib.hasInfix "\r" key) cfg.agentKeys);
            message = "ryk.vasherPrebuild.agentKeys entries must not contain a newline or a carriage return.";
          }
        ];

        users.groups.vasher-agent = { };
        users.users.vasher-agent = {
          isSystemUser = true;
          group = "vasher-agent";
          # No supplementary groups: the channel user is not in the vasher
          # group, so it cannot read the deploy key or the GitHub token.
          extraGroups = [ ];
          home = "/var/lib/vasher-agent";
          createHome = true;
          homeMode = "0700";
          # sshd runs the forced command through the login shell.
          shell = pkgs.bashInteractive;
          openssh.authorizedKeys.keys = map (
            key: ''command="${agent}/bin/vasher-agent-verb",restrict ${key}''
          ) cfg.agentKeys;
        };

        security.polkit.enable = true;
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (subject.user !== "vasher-agent") {
              return polkit.Result.NOT_HANDLED;
            }
            if (action.id !== "org.freedesktop.systemd1.manage-units") {
              return polkit.Result.NO;
            }
            var unit = action.lookup("unit");
            if (action.lookup("verb") === "start" &&
                (unit === "vasher-prebuild-retry.service" ||
                 unit === "vasher-prebuild-narrow.service")) {
              return polkit.Result.YES;
            }
            return polkit.Result.NO;
          });
        '';
        services.caddy = {
          enable = true;
          virtualHosts."http://:5080".extraConfig = ''
            handle /api/status.json {
              rewrite * /status.json
              root * /var/lib/vasher/dashboard
              file_server
            }
            handle /api/history.json {
              rewrite * /history.json
              root * /var/lib/vasher/dashboard
              file_server
            }
            handle /api/log.txt {
              rewrite * /log.txt
              root * /var/lib/vasher/dashboard
              file_server
            }
            handle /api/events.json {
              rewrite * /events.json
              root * /var/lib/vasher/dashboard
              file_server
            }
            handle /api/agent-events.json {
              rewrite * /events.json
              root * /var/lib/vasher/agent
              file_server
            }
            handle /api/holds.json {
              rewrite * /holds.json
              root * /var/lib/vasher/agent
              file_server
            }
            handle {
              root * ${dashboard}/share/vasher-dashboard
              try_files {path} /index.html
              file_server
            }
          '';
        };
        networking.firewall.interfaces.eth0.allowedTCPPorts = [ 5080 ];
      };
    };
}
