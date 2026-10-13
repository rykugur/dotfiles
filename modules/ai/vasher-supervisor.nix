{ inputs, ... }:
{
  flake.modules.homeManager.vasher-supervisor =
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
          inputs.hermes-agent.packages.${pkgs.system}.default
          pkgs.jq
          pkgs.libnotify
          pkgs.openssh
        ];
        text = builtins.readFile ./vasher-supervise.sh;
      };
    in
    {
      options.ryk.vasherSupervisor.enable = lib.mkEnableOption "scheduled Vasher supervision through Hermes";

      config = lib.mkIf cfg.enable {
        home.packages = [ vasherSupervise ];

        systemd.user.services.vasher-supervise = {
          Unit.Description = "Triage new Vasher incidents";
          Service = {
            Type = "oneshot";
            ExecStart = "${vasherSupervise}/bin/vasher-supervise";
          };
        };
        systemd.user.timers.vasher-supervise = {
          Unit.Description = "Poll Vasher every 30 minutes";
          Timer = {
            OnCalendar = "*:0/30";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };

        systemd.user.services.vasher-supervise-digest = {
          Unit.Description = "Write the weekly Vasher digest";
          Service = {
            Type = "oneshot";
            ExecStart = "${vasherSupervise}/bin/vasher-supervise --digest";
          };
        };
        systemd.user.timers.vasher-supervise-digest = {
          Unit.Description = "Run the weekly Vasher digest";
          Timer = {
            OnCalendar = "Mon *-*-* 09:00:00";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
}
