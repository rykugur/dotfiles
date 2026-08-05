{ ... }:
{
  flake.modules.nixos.vasher-prebuild =
    { config, lib, pkgs, ... }:
    let
      cfg = config.ryk.vasherPrebuild;
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
          set -Eeuo pipefail

          REPO_URL=${lib.escapeShellArg cfg.repoUrl}
          TARGET_ATTR=${lib.escapeShellArg cfg.targetAttr}
          CACHE_BRANCH=${lib.escapeShellArg cfg.cacheBranch}
          KEEP_ROOTS=${toString cfg.keepRoots}
          EXCLUDED_PACKAGES=${lib.escapeShellArg (builtins.toJSON cfg.excludedPackages)}
          mode=$1
          status=/var/lib/vasher/last-build.json
          base_revision=
          candidate_revision=
          out=
          status_tmp="$status.$$"
          lock_acquired=false

          cleanup_status_tmp() {
            rm -f "$status_tmp"
          }
          trap cleanup_status_tmp EXIT

          write_status() {
            local state=$1
            local exit_code=$2
            rm -f "$status_tmp"
            jq -n \
              --arg state "$state" \
              --arg mode "$mode" \
              --arg baseRevision "$base_revision" \
              --arg revision "$candidate_revision" \
              --arg output "$out" \
              --argjson exitCode "$exit_code" \
              --argjson excludedPackages "$EXCLUDED_PACKAGES" \
              '{
                state: $state,
                mode: $mode,
                baseRevision: $baseRevision,
                revision: $revision,
                output: $output,
                excludedPackages: $excludedPackages
              } + if $exitCode == null then {} else { exitCode: $exitCode } end' \
              > "$status_tmp"
            mv "$status_tmp" "$status"
          }

          record_failure() {
            local exit_code=$?
            trap - ERR
            [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
            exit "$exit_code"
          }
          trap record_failure ERR

          record_interruption() {
            local exit_code=$1
            trap - ERR INT TERM
            [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
            exit "$exit_code"
          }
          trap 'record_interruption 130' INT
          trap 'record_interruption 143' TERM

          exec 9>/var/lib/vasher/prebuild.lock
          case $mode in
            refresh) flock -n 9 || exit 0; lock_acquired=true ;;
            candidate) flock 9; lock_acquired=true ;;
            *) printf 'vasher-prebuild: unknown mode %s\n' "$mode" >&2; exit 2 ;;
          esac

          repo=/var/lib/vasher/repo
          roots=/var/lib/vasher/gcroots
          mkdir -p "$roots"
          [[ -d "$repo/.git" ]] || git clone "$REPO_URL" "$repo"
          git -C "$repo" fetch --prune origin
          base_revision=$(git -C "$repo" rev-parse origin/master)

          candidate_covers_base() {
            git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$CACHE_BRANCH" &&
              git -C "$repo" merge-base --is-ancestor "$base_revision" "origin/$CACHE_BRANCH"
          }

          prune_roots() {
            # shellcheck disable=SC2012
            mapfile -t stale < <(ls -1t "$roots" | tail -n +$((KEEP_ROOTS + 1)))
            for root in "''${stale[@]}"; do rm -f "$roots/$root"; done
          }

          if [[ $mode == refresh ]] && candidate_covers_base; then
            write_status idle null
            exit 0
          fi

          write_status building null
          worktree=/var/lib/vasher/worktrees/"$mode"
          if [[ ! -e "$worktree/.git" ]]; then
            mkdir -p "$(dirname "$worktree")"
            git -C "$repo" worktree add --detach "$worktree" "$base_revision"
          fi
          git -C "$worktree" reset --hard "$base_revision"

          nix flake update --flake "$worktree"
          (
            cd "$worktree"
            ${pkgs.bash}/bin/bash ${../ai/oh-my-pi/update-omp.sh}
          )

          out=$(nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
          git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json
          if ! git -C "$worktree" diff --cached --quiet; then
            git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
              commit -m "chore: refreshed flake.lock and OMP update ($(date -I))"
          fi
          candidate_revision=$(git -C "$worktree" rev-parse HEAD)

          root_path="$roots/''${out##*/}"
          if [[ ! -e "$root_path" ]]; then
            nix-store --add-root "$root_path" --indirect --realise "$out"
          fi
          touch -h "$root_path"


          git -C "$repo" fetch origin master
          if [[ $(git -C "$repo" rev-parse origin/master) != "$base_revision" ]]; then
            prune_roots
            write_status stale null
            exit 0
          fi

          git -C "$worktree" push --force-with-lease origin "HEAD:refs/heads/$CACHE_BRANCH" || {
            git -C "$worktree" fetch origin "$CACHE_BRANCH:refs/remotes/origin/$CACHE_BRANCH"
            git -C "$worktree" push --force-with-lease origin "HEAD:refs/heads/$CACHE_BRANCH"
          }
          prune_roots

          nix-collect-garbage

          write_status success null
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
          default = 5;
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets."swoleflake/deploy_key" = {
          key = "swoleflake/deploy_key";
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
      };
    };
}
