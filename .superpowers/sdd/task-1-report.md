# Task 1 Report: Vasher Generator Input and LXC Host

## Changed files

- `flake.nix` — added the `nixos-generators` input, following `nixpkgs`.
- `flake.lock` — locked `nixos-generators` and its `nixlib` dependency.
- `modules/hosts/vasher/default.nix` — registered the x86_64-linux Vasher NixOS configuration from the defaults, role, and LXC platform modules.
- `modules/hosts/vasher/_role.nix` — defined the platform-independent Vasher hostname, Nix cache policy, service account, SSH policy, SOPS configuration, firewall, packages, and state version.
- `modules/hosts/vasher/_platform-lxc.nix` — defined Proxmox LXC-specific settings. `proxmoxLXC.manageHostName = true` is required because the upstream module otherwise forces `networking.hostName` to an empty string when network management is disabled.

No plaintext or placeholder secret/key files were created. The role has no declared SOPS secrets, so its future `defaultSopsFile` reference does not participate in this evaluation. The encrypted secrets file and cache signing public key require the later provisioning/signing tasks and are intentionally absent.

## Verification

Command:

```sh
nix eval .#nixosConfigurations.vasher.config.networking.hostName
```

Output:

```text
warning: Git tree '/home/dusty/projects/dotfiles/.worktrees/feat-vasher-binary-cache' is dirty
Using saved setting for 'extra-substituters = https://hyprland.cachix.org https://nix-gaming.cachix.org https://nix-citizen.cachix.org https://helix.cachix.org https://pi.cachix.org' from ~/.local/share/nix/trusted-settings.json.
Using saved setting for 'extra-trusted-public-keys = hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4= nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo= helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs= pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk=' from ~/.local/share/nix/trusted-settings.json.
warning: updating lock file "/home/dusty/projects/dotfiles/.worktrees/feat-vasher-binary-cache/flake.lock":
• Added input 'nixos-generators':
    'github:nix-community/nixos-generators/8946737ff703382fda7623b9fab071d037e897d5?narHash=sha256-nnVmNNKBi1YiBNPhKclNYDORoHkuKipoz7EtVnXO50A%3D' (2026-01-30)
• Added input 'nixos-generators/nixlib':
    'github:nix-community/nixpkgs.lib/1418bc28a52126761c02dd3d89b2d8ca0f521181?narHash=sha256-tmpqTSWVRJVhpvfSN9KXBvKEXplrwKnSZNAoNPf/S/s%3D' (2025-01-12)
• Added input 'nixos-generators/nixpkgs':
    follows 'nixpkgs'
"vasher"
```

## Commits

- `7dacec8e feat(hosts): add Vasher LXC host role`
- This report is committed separately as `docs(sdd): record Vasher host Task 1`.

## Self-review

- The generator input is adjacent to `import-tree` and follows the existing flake-input style.
- The role/LXC separation is preserved; only LXC-specific options are in `_platform-lxc.nix`.
- Vasher is fixed to `x86_64-linux`; no remote-builder configuration is added.
- The configuration evaluates to the required hostname without secret material or placeholders.
- Future cache/prebuild modules are not referenced yet because they do not exist in this task's repository state; doing so would prevent the required initial host evaluation.
