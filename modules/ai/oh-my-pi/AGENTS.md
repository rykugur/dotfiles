# Personal Instructions

- Prefer simple, maintainable solutions.
- Keep changes focused on the request.
- Verify significant changes before reporting completion.

## Project Change History

- Arcanum is the single wiki and the source of truth for changes and decisions made with Dusty in dotfiles, homelab, and other personal projects. Those repos keep no `wiki/` and no `docs/`; they hold code, a `README.md`, and a `CLAUDE.md` that points at Arcanum.
- Before completing such work, read Arcanum's `CLAUDE.md`, `index.md`, and the recent entries in the current month's `log/YYYY-MM.md`. Record each change or related batch as a new entry there — heading `## [YYYY-MM-DD] <verb> | <title>` followed by `**Project:** <name>` — stating what changed, why, decisions and tradeoffs, affected paths, and observed results or uncertainty. Update the relevant page under `wiki/Projects/<Name>/` for durable decisions.
- Keep durable documentation in Arcanum, not in the project repo. If Arcanum is unavailable, report that the change was not logged rather than claiming it was.

## System Configuration

- Never run a command that activates or changes the CURRENT machine's NixOS, nix-darwin, or Home Manager configuration — i.e. no `--target-host`/remote target, or any invocation defaulting to the local system. This rule includes live `nixos-rebuild switch`/`boot`, `darwin-rebuild switch`, and `home-manager switch` runs against the machine the agent is running on.
- Activating a REMOTE host (`nixos-rebuild`/`darwin-rebuild switch --target-host <other-host>`, never the current machine) is allowed, but only after asking and receiving explicit permission for that specific run. Do not run a remote switch unprompted, and do not treat an earlier approval as standing permission for a later run.
- Commands that only evaluate, build, check, or perform a dry run are allowed, for local or remote targets. `nix flake check` is allowed.

## Secrets

- NEVER decrypt a sops/age/gpg-encrypted file for any reason — no `sops -d`, `sops exec-file`, `age -d`, `gpg -d`, or piping an encrypted file through a decrypt command, even to "just check" a value. This holds regardless of the `sensitive-files` skill triggering. Applies to `*.sops.yaml`/`*.sops.yml`/`*.sops.json` and any other sops/age/gpg-encrypted file.
- Reading an encrypted file's ciphertext is fine (it's not a secret) — use it to tell Dusty which key(s) are missing or need changing. Still never read the plaintext of unencrypted secret files (`.env`, `secrets.yaml` that isn't sops-encrypted, `*.tfvars`, raw keys, etc. — see the `sensitive-files` skill).
- Dusty edits existing secrets himself (`sops secrets.yaml` or equivalent). The agent's role is to point out which key needs adding/changing, not to edit or decrypt the file.
- For a brand-new secret that doesn't exist yet: create a new, unencrypted placeholder file (or a clearly marked placeholder block) for Dusty to fill in and encrypt himself. Do not attempt to encrypt it yourself, and do not guess or fabricate a value.

## Shell

- Copy/paste commands for Dusty MUST be valid in **his** interactive shell, not bash-by-default. That shell is currently **nushell**. Do not give `export`, bash `&&` chains, or bash-only redirects unless he asks for bash. Agent-side tool commands may still use bash.


## Session Status

- On any turn that did substantive work (edited files, ran commands, multi-step investigation) end the reply with a footer line: `**Status:** <project/task name> — <current state or immediate next step>`. Skip it on short one-off Q&A turns with no work attached.
- When a project or task reaches genuine completion — every acceptance criterion met, nothing actionable left — replace that footer with `**Done:** <1-3 sentence summary of what was accomplished>`.
