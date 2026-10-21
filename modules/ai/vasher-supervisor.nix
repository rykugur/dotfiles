{ inputs, ... }:
{
  # Runs on the always-on Hermes host, not on a desktop. Polling is cheap and
  # deterministic; Hermes is only invoked when an incident exists.
  flake.modules.nixos.vasher-supervisor =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.vasherSupervisor;
      vasherSupervise = pkgs.writeShellApplication {
        name = "vasher-supervise";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.jq
          pkgs.openssh
          pkgs.util-linux
        ];
        text = builtins.readFile ./vasher-supervise.sh;
      };
      environment = {
        HOME = cfg.hermesHome;
        VASHER_SUPERVISE_STATE = "/var/lib/vasher-supervise";
        VASHER_SUPERVISE_KEY = cfg.agentKey;
      }
      // lib.optionalAttrs (cfg.sendTarget != null) {
        VASHER_SUPERVISE_SEND_TARGET = cfg.sendTarget;
      };
      service = args: {
        description = "Triage new Vasher incidents";
        inherit environment;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${vasherSupervise}/bin/vasher-supervise${args}";
          TimeoutStartSec = "7min";
          User = cfg.user;
          Group = cfg.user;
          StateDirectory = "vasher-supervise";
          StateDirectoryMode = "0700";
        };
      };
      timer = onCalendar: {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = onCalendar;
          Persistent = true;
        };
      };
    in
    {
      options.ryk.vasherSupervisor = {
        user = lib.mkOption {
          type = lib.types.str;
          default = "hermes";
          description = "Service user. Must be the user that owns the Hermes state directory.";
        };
        hermesHome = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/hermes";
          description = "HOME for the Hermes CLI. Hermes refuses to start without its own state directory.";
        };
        agentKey = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/hermes/.ssh/vasher-agent";
          description = "Private key for the Vasher action channel. While this file is absent, proposals are written to the digest and no action is attempted.";
        };
        sendTarget = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "telegram";
          description = "Hermes gateway target for alerts, as accepted by `hermes send -t`. Alerts always reach the journal; this adds an off-host channel.";
        };
      };

      config = {
        environment.systemPackages = [ vasherSupervise ];

        systemd.services.vasher-supervise = service "";
        systemd.timers.vasher-supervise = timer "*:0/30";

        systemd.services.vasher-supervise-digest = service " --digest" // {
          description = "Write the weekly Vasher digest";
        };
        systemd.timers.vasher-supervise-digest = timer "Mon *-*-* 09:00:00";
      };
    };
}
