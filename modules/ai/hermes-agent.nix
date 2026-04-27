{ inputs, ... }:
{
  flake.modules.homeManager.hermes-agent =
    { pkgs, ... }:
    let
      hermes-agent-pkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
    in
    {
      home.packages = [ hermes-agent-pkg ];

      systemd.user.services.hermes-webui = {
        Unit = {
          Description = "Hermes WebUI";
          After = [ "network.target" ];
        };
        Service = {
          ExecStart = "${python}/bin/python3 ${inputs.hermes-webui}/server.py";
          WorkingDirectory = "${inputs.hermes-webui}";
          Environment = [
            "HERMES_HOME=%h/.hermes"
            "HERMES_WEBUI_AGENT_DIR=${hermes-agent-pkg}"
          ];
          Restart = "on-failure";
          RestartSec = "3s";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
