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
          mode=$1
          status=/var/lib/vasher/last-build.json
          record_failure() {
            local exit_code=$?
            trap - ERR
            jq -n --arg mode "$mode" --argjson exitCode "$exit_code" \
              '{status:"failed",mode:$mode,exitCode:$exitCode}' > "$status" || true
            exit "$exit_code"
          }
          trap record_failure ERR

          exec 9>/var/lib/vasher/prebuild.lock
          flock -n 9 || exit 0

          repo=/var/lib/vasher/repo
          roots=/var/lib/vasher/gcroots
          mkdir -p "$roots"
          [[ -d "$repo/.git" ]] || git clone "$REPO_URL" "$repo"
          git -C "$repo" fetch origin master
          worktree=/var/lib/vasher/worktrees/"$mode"
          if [[ ! -e "$worktree/.git" ]]; then
            mkdir -p "$(dirname "$worktree")"
            git -C "$repo" worktree add --detach "$worktree" origin/master
          fi
          git -C "$worktree" fetch origin master
          git -C "$worktree" reset --hard origin/master

          if [[ $mode == candidate ]]; then
            nix flake update --flake "$worktree"
          fi

          out=$(nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
          if [[ $mode == candidate ]]; then
            git -C "$worktree" add flake.lock
            if ! git -C "$worktree" diff --cached --quiet; then
              git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
                commit -m "chore: nightly flake.lock update ($(date -I))"
            fi
            git -C "$worktree" push --force-with-lease origin "HEAD:$CACHE_BRANCH" || {
              git -C "$worktree" fetch origin "$CACHE_BRANCH:refs/remotes/origin/$CACHE_BRANCH"
              git -C "$worktree" push --force-with-lease origin "HEAD:$CACHE_BRANCH"
            }
          fi

          root_path="$roots/$(date -u +%Y%m%dT%H%M%SZ)-$mode"
          nix-store --add-root "$root_path" --indirect --realise "$out"
          # shellcheck disable=SC2012
          mapfile -t stale < <(ls -1t "$roots" | tail -n +$((KEEP_ROOTS + 1)))
          for root in "''${stale[@]}"; do rm -f "$roots/$root"; done
          nix-collect-garbage

          jq -n --arg mode "$mode" --arg out "$out" --arg revision "$(git -C "$worktree" rev-parse HEAD)" \
            '{status:"success",mode:$mode,output:$out,revision:$revision}' > "$status"
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
          vasher-prebuild-master = service "master";
          vasher-prebuild-candidate = service "candidate";
        };

        systemd.timers.vasher-prebuild-master = {
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
