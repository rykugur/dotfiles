{ inputs, ... }:
let
  # grok (superagent-ai/grok-cli) uses ~/.agents/skills/ for user-level skills
  # (and project .agents/skills/). This matches the AGENTS.md-compatible location
  # also used by codex, so skills are shared automatically. Grok also supports
  # its own .grok/skills/ and AGENTS.md family for instructions.
  #
  # Project-level state (model prefs, sessions, etc.) goes in .grok/ in the cwd.
  # This directory is intentionally gitignored (see top-level .gitignore).

  inherit ((import ./_skills.nix { inherit inputs; })) skillsForDotAgents;
  skills = skillsForDotAgents;
in
{
  flake.modules.homeManager.grok =
    { ... }:
    {
      # grok-cli requires an API key to be set and I don't care enough right now.
      # home.packages = [ pkgs.grok-cli ];

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}";
          value.source = skill.src;
        }) skills
      );

      # Expose the stock package for convenience (e.g. nix build .#grok or in dev shells).
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.grok = pkgs.grok-cli;
    };
}
