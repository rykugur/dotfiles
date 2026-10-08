{ inputs, ... }:
{
  flake.modules.homeManager.codex =
    { pkgs, ... }:
    let
      inherit ((import ./_skills.nix { inherit inputs pkgs; })) skillsForDotAgents;
      skills = skillsForDotAgents;
    in
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
