# Phase 4: the rig itself — /world, the read-only rules, the OpenRig daemon,
# the hourly wake, and the loopback viewer. See [[OpenRig Agent World]].
{
  inputs,
  pkgs,
  config,
  ...
}:
let
  omp = inputs.oh-my-pi.packages.${pkgs.system}.omp;

  # The specs and rules, immutable in the store. Agents have root and can
  # remount over this; nothing important depends on them not doing it.
  worldSrc = ./world;

  user = "world";
  worldDir = "/world";
  rigRoot = "/etc/world";

  # Model is set per-member in world/rig.yaml:
  # opencode-go/deepseek-v4.1-flash for all five, Honor included.

  seats = [
    "cultivation"
    "whimsy"
    "preservation"
    "ruin"
    "honor"
  ];

  rigCli = "${pkgs.openrig}/bin/rig";
in
{
  environment.systemPackages = [ omp ];

  # The daemon reads OPENCODE_API_KEY from its own environment and hands it
  # to seats whose model is `opencode-go/...` (oh-my-pi's provider map; the
  # allowlist below is what permits it through).
  #
  # The secret must be declared, not just referenced: `sops.placeholder.<n>`
  # only resolves for a declared `sops.secrets.<n>`. Declaring templates
  # alone left sops-nix with nothing to activate, so /run/secrets was never
  # created and the daemon died 50+ times on "Failed to load environment
  # files".
  sops.secrets.opencode_api_key = { };

  sops.templates."openrig-env" = {
    content = ''
      OPENCODE_API_KEY=${config.sops.placeholder.opencode_api_key}
    '';
    owner = user;
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d ${worldDir} 0755 ${user} users -"
    "d ${worldDir}/journals 0755 ${user} users -"
    "d ${worldDir}/projects 0755 ${user} users -"
    "d ${worldDir}/www 0755 ${user} users -"
    "d ${worldDir}/proposals 0755 ${user} users -"
    "d ${worldDir}/chatlog 0755 ${user} users -"
    "d ${worldDir}/digest 0755 ${user} users -"
  ];

  # Rules and specs are a read-only bind of the store path.
  environment.etc."world".source = worldSrc;

  # `/world` is a git repo with no remote. Its history is the world's memory,
  # so this only ever initialises — it never resets an existing repo.
  systemd.services.world-init = {
    description = "Initialise /world as a local git repository";
    wantedBy = [ "multi-user.target" ];
    before = [ "openrig-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      WorkingDirectory = worldDir;
    };
    path = [ pkgs.git ];
    script = ''
      if [ ! -d ${worldDir}/.git ]; then
        git init -b main
        git config user.name "the world"
        git config user.email "world@elantris.local.ryk.sh"
        printf '%s\n' "# The World" "" \
          "See /etc/world/CULTURE.md and /etc/world/RULES.md." > README.md
        git add -A
        git commit -m "the world begins" --allow-empty
      fi
    '';
  };

  systemd.services.openrig-daemon = {
    description = "OpenRig daemon (headless, no kernel)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "world-init.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      # Run the daemon itself in the foreground rather than going through
      # `rig daemon start`. That command is a launcher: it spawns the daemon
      # child, polls it for liveness, then exits. Under systemd the child
      # got SIGTERM mid-verification — its own log shows
      # "listening on http://127.0.0.1:7433" immediately followed by
      # "received SIGTERM" — so the launcher reported "liveness could not be
      # confirmed" and the unit flapped. Type=forking didn't help. Invoking
      # the entrypoint directly makes the daemon systemd's main process,
      # which is what we actually want for a supervised service.
      #
      # This reaches into the package layout, which is acceptable only
      # because pkgs/openrig.nix pins 0.6.5 in-repo: an upgrade is a
      # deliberate edit where this path gets re-checked.
      Type = "simple";
      User = user;
      WorkingDirectory = worldDir;
      EnvironmentFile = config.sops.templates."openrig-env".path;
      Restart = "on-failure";
      RestartSec = 10;
    };
    environment = {
      # No Claude/Codex account here, so there is no kernel to start.
      OPENRIG_NO_KERNEL = "1";
    };
    path = [
      pkgs.openrig
      omp
      pkgs.git
      pkgs.tmux
      pkgs.nodejs_22
    ];
    preStart = ''
      # Idempotent: lets the daemon pass OPENCODE_API_KEY through to the
      # opencode-go seats. RigSpec `env:` can't carry it — those values are
      # documented as not secret and this spec is in the Nix store.
      ${rigCli} config set recovery.provider_auth_env_allowlist '["OPENCODE_API_KEY"]' || true
    '';
    script = ''
      exec ${pkgs.nodejs_22}/bin/node \
        ${pkgs.openrig}/lib/node_modules/@openrig/cli/daemon/dist/index.js
    '';
  };

  # Resume an existing world by name. On a clean installation, import the
  # spec once; a failed resume must not silently launch fresh seats.
  systemd.services.world-up = {
    description = "Start the world rig";
    wantedBy = [ "multi-user.target" ];
    after = [ "openrig-daemon.service" ];
    requires = [ "openrig-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      WorkingDirectory = worldDir;
      EnvironmentFile = config.sops.templates."openrig-env".path;
    };
    path = [
      pkgs.openrig
      omp
      pkgs.git
      pkgs.tmux
      pkgs.nodejs_22
    ];
    script = ''
      if ${rigCli} ps --json | ${pkgs.jq}/bin/jq -e 'any(.[]; .name == "world")' >/dev/null; then
        ${rigCli} up world --existing --yes
      else
        ${rigCli} up ${rigRoot}/rig.yaml --yes
      fi
    '';
  };

  # Hourly wake. A wake is an opportunity, not an instruction — a member
  # that reads the chatlog and decides to do nothing has taken a full turn.
  systemd.services.world-wake = {
    description = "Wake every resident of the world";
    after = [ "world-up.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = worldDir;
      EnvironmentFile = config.sops.templates."openrig-env".path;
    };
    path = [
      pkgs.openrig
      omp
      pkgs.git
      pkgs.tmux
      pkgs.nodejs_22
    ];
    script = ''
      ${builtins.concatStringsSep "\n" (
        map (s: ''
          ${rigCli} send residents-${s}@world "An hour has passed. Read the chatlog and your journal, then do whatever you think is worth doing — including nothing." || true
        '') seats
      )}
    '';
  };

  systemd.timers.world-wake = {
    description = "Wake the world hourly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
  };

  # The viewer. Reachable directly from jezrien rather than through an SSH
  # tunnel: the UniFi allow for this VLAN covers tcp/22,8080 from Dusty's
  # workstation IP only, and everything else inbound still hits the block.
  # The agents control what lands in /world/www, so this is a (small,
  # deliberate) widening of what they can serve straight to a browser.
  networking.firewall.allowedTCPPorts = [ 8080 ];

  services.caddy = {
    enable = true;
    virtualHosts.":8080".extraConfig = ''
      root * ${worldDir}/www
      file_server browse
    '';
  };
}
