{ inputs, ... }:
let
  skills = [
    { name = "frontend-design"; src = "${inputs.skills-anthropic}/skills/frontend-design"; }
    { name = "web-design-guidelines"; src = "${inputs.skills-vercel}/skills/web-design-guidelines"; }
    { name = "karpathy-guidelines"; src = "${inputs.karpathy-skills}/skills/karpathy-guidelines"; }
    { name = "llm-wiki"; src = ./skills/llm-wiki; }
  ];
in
{
  flake.modules.homeManager.codex =
    { ... }:
    {
      programs.codex.enable = true;

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}/SKILL.md";
          value.source = "${skill.src}/SKILL.md";
        }) skills
      );
    };
}
