{ inputs, ... }:
let
  # grok (superagent-ai/grok-cli) uses ~/.agents/skills/ for user-level skills
  # (and project .agents/skills/). This matches the AGENTS.md-compatible location
  # also used by codex, so skills are shared automatically. Grok also supports
  # its own .grok/skills/ and AGENTS.md family for instructions.
  #
  # Project-level state (model prefs, sessions, etc.) goes in .grok/ in the cwd.
  # This directory is intentionally gitignored (see top-level .gitignore).

  skills = [
    { name = "frontend-design"; src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines"; src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
    { name = "karpathy-guidelines"; src = "${inputs.karpathy-skills}/skills/karpathy-guidelines"; }
    { name = "sensitive-files"; src = ./skills/sensitive-files; }
    { name = "llm-wiki"; src = ./skills/llm-wiki; }
  ];
in
{
  flake.modules.homeManager.grok =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.grok-cli ];

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}/SKILL.md";
          value.source = "${skill.src}/SKILL.md";
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
