{ inputs }:
let
  # Skills installed for agents that consume the shared .agents/skills/ layout
  # (and equivalent for other harnesses).
  #
  # These are in addition to (or instead of) plugin-based loading for some agents.
  # See claude-code.nix (pluginDirs) and opencode.nix (plugin list) for the
  # superpowers integration on those harnesses.

  commonSkills = [
    {
      name = "frontend-design";
      src = "${inputs.skills-anthropic}/skills/frontend-design";
    }
    {
      name = "web-design-guidelines";
      src = "${inputs.skills-vercel}/skills/web-design-guidelines";
    }
    {
      name = "karpathy-guidelines";
      src = "${inputs.karpathy-skills}/skills/karpathy-guidelines";
    }
    {
      name = "sensitive-files";
      src = ./skills/sensitive-files;
    }
    {
      name = "llm-wiki";
      src = ./skills/llm-wiki;
    }
  ];

  # Superpowers skills (https://github.com/obra/superpowers).
  # Full set of composable agentic development skills: TDD, systematic debugging,
  # brainstorming, writing-plans, subagent-driven-development, using-git-worktrees,
  # requesting-code-review, etc. The using-superpowers skill acts as bootstrap
  # to ensure skills are considered before acting.
  #
  # We expose the entire skill directory (not just SKILL.md) so companion
  # documents (testing-anti-patterns.md, references/, examples/, etc.) are
  # present for agents that Read or @-include them.
  superpowersDir = "${inputs.superpowers}/skills";
  superpowersSkillNames = builtins.attrNames (builtins.readDir superpowersDir);
  superpowersSkills = map (name: {
    inherit name;
    src = "${superpowersDir}/${name}";
  }) superpowersSkillNames;

  # For .agents/skills consumers (codex, grok) and any other that wants the
  # full set including superpowers methodology.
  skillsForDotAgents = commonSkills ++ superpowersSkills;
in
{
  inherit
    commonSkills
    superpowersSkills
    skillsForDotAgents
    ;
}
