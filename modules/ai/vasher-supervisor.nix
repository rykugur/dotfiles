{ inputs, ... }:
{
  flake.modules.homeManager.vasher-supervisor =
    { pkgs, ... }:
    let
      vasherSupervise = pkgs.writeShellApplication {
        name = "vasher-supervise";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          inputs.hermes-agent.packages.${pkgs.system}.default
          pkgs.jq
          pkgs.libnotify
          pkgs.openssh
          pkgs.util-linux
        ];
        text = builtins.readFile ./vasher-supervise.sh;
      };
    in
    {
      home.packages = [ vasherSupervise ];

      systemd.user.services.vasher-supervise = {
        Unit.Description = "Triage new Vasher incidents";
        Service = {
          Type = "oneshot";
          ExecStart = "${vasherSupervise}/bin/vasher-supervise";
          TimeoutStartSec = "7min";
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
          TimeoutStartSec = "7min";
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
}
