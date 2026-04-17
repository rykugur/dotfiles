{ inputs, ... }:
{
  flake.modules.homeManager.hermes-agent =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.hermes-agent.packages.${pkgs.system}.default
      ];
    };
}
