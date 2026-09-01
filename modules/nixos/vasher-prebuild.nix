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
          curl
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
          export OMP_UPDATER=${lib.escapeShellArg ../ai/oh-my-pi/update-omp.sh}
          exec ${pkgs.bash}/bin/bash ${runtime} "$@"
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
        enable = lib.mkEnableOption "serialized Vasher prebuild jobs";
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
      };

      config = lib.mkIf cfg.enable {
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

        systemd.services = {
          vasher-prebuild-refresh = service "refresh";
          vasher-prebuild-candidate = service "candidate";
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
