{ ... }:
{
  flake.modules.homeManager.grok = {
    # grok-cli requires an API key to be set and I don't care enough right now.
    # home.packages = [ pkgs.grok-cli ];
    # Skills live in ~/.agents/skills via ai-skills, which grok-cli also reads.
  };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
