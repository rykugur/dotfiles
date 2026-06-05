{ inputs, ... }:
let
  inherit ((import ./_skills.nix { inherit inputs; })) skillsForDotAgents;
  skills = skillsForDotAgents;
in
{
  flake.modules.homeManager.codex =
    { ... }:
    {
      programs.codex.enable = true;

      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}";
          value.source = skill.src;
        }) skills
      );
    };
}
