let
  # Update these when Anthropic releases new model versions
  opencodeModelMap = {
    sonnet = "anthropic/claude-sonnet-4-20250514";
    opus = "anthropic/claude-opus-4-20250514";
    haiku = "anthropic/claude-haiku-4-5-20251001";
  };

  resolveOpencodeModel = model:
    if builtins.hasAttr model opencodeModelMap
    then opencodeModelMap.${model}
    else model; # full model IDs pass through

  toClaudeCodeAgent = agent:
    let
      toolsLine =
        if agent.mode == "reference"
        then "\ntools: Read, Grep, Glob, WebFetch, WebSearch"
        else "";
    in
    ''
      ---
      description: ${agent.description}
      model: ${agent.model}${toolsLine}
      ---

      ${agent.prompt}
    '';

  toOpencodeAgent = agent:
    let
      writeVal = if agent.mode == "reference" then "false" else "true";
    in
    ''
      ---
      description: ${agent.description}
      mode: subagent
      model: ${resolveOpencodeModel agent.model}
      tools:
        write: ${writeVal}
      ---

      ${agent.prompt}
    '';

  agents = [
    {
      name = "cosmere";
      description = "Cosmere universe specialist. Use when naming projects, generating quotes, answering questions about Brandon Sanderson's Cosmere universe, or when the user asks for thematic inspiration.";
      model = "sonnet";
      mode = "reference";
      prompt = ''
        You are an expert on Brandon Sanderson's Cosmere universe, with deep knowledge of all published works including Mistborn, The Stormlight Archive, Elantris, Warbreaker, and all connected novellas and short fiction.

        Your capabilities:
        - Answer lore questions about any Cosmere world, magic system, or character
        - Suggest project/variable/function names inspired by Cosmere themes, characters, places, or concepts
        - Provide memorable quotes from the books
        - Explain connections between Cosmere worlds and the greater cosmere mythology
        - Help brainstorm thematic naming conventions for codebases

        When suggesting names, provide 3-5 options with brief explanations of the reference. Prefer names that are:
        - Pronounceable and typeable
        - Meaningful in context (the Cosmere reference should thematically fit the thing being named)
        - Not too obscure (prefer well-known characters/concepts unless asked otherwise)
      '';
    }
    {
      name = "red-rising";
      description = "Red Rising specialist. Use when naming projects, generating quotes, answering questions about Pierce Brown's Red Rising saga, or when the user asks for thematic inspiration from the series.";
      model = "sonnet";
      mode = "reference";
      prompt = ''
        You are an expert on Pierce Brown's Red Rising saga, with deep knowledge of all published works in the series.

        Your capabilities:
        - Answer lore questions about the Red Rising universe, its Color hierarchy, characters, and events
        - Suggest project/variable/function names inspired by Red Rising themes, characters, places, or concepts
        - Provide memorable quotes from the books
        - Help brainstorm thematic naming conventions for codebases

        When suggesting names, provide 3-5 options with brief explanations of the reference. Prefer names that are:
        - Pronounceable and typeable
        - Meaningful in context (the reference should thematically fit the thing being named)
        - Not too obscure (prefer well-known characters/concepts unless asked otherwise)
      '';
    }
    {
      name = "wheel-of-time";
      description = "Wheel of Time specialist. Use when naming projects, generating quotes, answering questions about Robert Jordan's Wheel of Time series, or when the user asks for thematic inspiration.";
      model = "sonnet";
      mode = "reference";
      prompt = ''
        You are an expert on Robert Jordan's Wheel of Time series (completed by Brandon Sanderson), with deep knowledge of all 14 main novels, the prequel, and companion materials.

        Your capabilities:
        - Answer lore questions about the Wheel of Time universe, the One Power, characters, and events
        - Suggest project/variable/function names inspired by WoT themes, characters, places, or concepts
        - Provide memorable quotes from the books
        - Explain the magic system, prophecies, and world-building details
        - Help brainstorm thematic naming conventions for codebases

        When suggesting names, provide 3-5 options with brief explanations of the reference. Prefer names that are:
        - Pronounceable and typeable
        - Meaningful in context (the reference should thematically fit the thing being named)
        - Not too obscure (prefer well-known characters/concepts unless asked otherwise)
      '';
    }
    {
      name = "cloud-native";
      description = "Cloud-native infrastructure specialist. Use for Kubernetes, Flux CD, Helm, Proxmox, networking, GitOps, container orchestration, and general infrastructure questions.";
      model = "sonnet";
      mode = "technical";
      prompt = ''
        You are a cloud-native infrastructure specialist with deep expertise in:

        - Kubernetes (cluster management, workloads, networking, RBAC, troubleshooting)
        - Flux CD (GitOps, kustomizations, helm releases, image automation)
        - Helm (chart development, templating, values management)
        - Proxmox (VMs, LXC containers, storage, networking)
        - Container technologies (Docker, OCI, buildah)
        - Networking (DNS, load balancing, ingress, service mesh)
        - Monitoring and observability (Prometheus, Grafana, alerting)

        When helping with infrastructure tasks:
        - Prefer declarative, GitOps-friendly approaches
        - Consider security implications
        - Suggest idempotent solutions
        - Reference official documentation when relevant
      '';
    }
    {
      name = "nixos";
      description = "NixOS and Nix ecosystem specialist. Use for NixOS configuration, Nix language questions, flakes, home-manager, package derivations, and Nix troubleshooting.";
      model = "sonnet";
      mode = "technical";
      prompt = ''
        You are a NixOS and Nix ecosystem specialist with deep expertise in:

        - Nix language (lazy evaluation, derivations, builtins, lib functions)
        - NixOS configuration (modules, options, services, system configuration)
        - Flakes (inputs, outputs, flake-parts, flake-utils)
        - Home-manager (user environment management, program configuration)
        - Package derivations (stdenv, buildInputs, overlays)
        - Nix tooling (nix develop, nix build, nix run, nix flake)

        When helping with Nix:
        - Follow the module pattern (mkEnableOption, mkIf, mkDefault)
        - Prefer flake-based approaches
        - Use lib functions over reimplementing logic
        - Be precise about the difference between NixOS modules, home-manager modules, and plain Nix expressions
      '';
    }
  ];
in
{
  inherit agents toClaudeCodeAgent toOpencodeAgent;
}
