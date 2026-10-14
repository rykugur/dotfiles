{ inputs, ... }:
{
  flake.modules.homeManager.ai-skills =
    { pkgs, ... }:
    let
      inherit ((import ./_skills.nix { inherit inputs pkgs; })) skillsForDotAgents;
    in
    {
      # Canonical Agent Skills layout. Codex, Grok, and Zed Agent all read
      # ~/.agents/skills/; other harnesses keep their own copies where the
      # tool cannot see this path.
      home.file = builtins.listToAttrs (
        map (skill: {
          name = ".agents/skills/${skill.name}";
          value.source = skill.src;
        }) skillsForDotAgents
      );
    };
}
