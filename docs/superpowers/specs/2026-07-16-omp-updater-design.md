# OMP release updater design

## Status

Design approved; specification pending review.

## Problem

`modules/ai/oh-my-pi/default.nix` pins standalone OMP release binaries. Updating it currently requires manually changing a version and every platform hash, while a separate manually maintained Carapace file creates unrelated Nushell-completion drift.

## Decision

Keep OMP declaratively Nix-managed, remove the Nushell/Carapace integration, and add one explicit flake updater command.

The command is:

```sh
nix run .#update-oh-my-pi
nix run .#update-oh-my-pi -- <version>
```

The no-argument form selects the latest stable GitHub release. The version form selects the exact stable release tag.

## Data model

Move release-specific data into `modules/ai/oh-my-pi/release.json`:

```json
{
  "version": "<version>",
  "sources": {
    "x86_64-linux": { "asset": "omp-linux-x64", "hash": "sha256-…" },
    "aarch64-linux": { "asset": "omp-linux-arm64", "hash": "sha256-…" },
    "x86_64-darwin": { "asset": "omp-darwin-x64", "hash": "sha256-…" },
    "aarch64-darwin": { "asset": "omp-darwin-arm64", "hash": "sha256-…" }
  }
}
```

`default.nix` reads this JSON file and retains responsibility for packaging: choosing the host asset, fetching it, Linux ELF setup, generated Fish/Bash completions, install check, and package metadata. The release data file is the updater's only mutable target.

All four existing module targets remain pinned and updated. Although this flake's local `perSystem` set excludes `x86_64-darwin`, retaining it preserves the exported Home Manager module's present compatibility for external consumers.

## Updater behavior

The updater is exposed as a runnable flake package and is implemented with Nix-provided command-line dependencies. It:

1. Resolves the repository root and refuses to operate outside this checkout.
2. Queries GitHub's release API for `latest` or the requested `v<version>` tag.
3. Rejects drafts, prereleases, invalid version arguments, missing expected assets, and missing upstream SHA-256 asset digests.
4. Maps the four expected release asset names to the four declared Nix systems.
5. Atomically rewrites only `release.json` with the selected version and SRI SHA-256 hashes.
6. Runs `nix build .#oh-my-pi`.
7. Reports the prior and selected versions on success.

The API digest is used instead of downloading every platform binary to calculate hashes. The subsequent native build independently fetches and hash-verifies the current platform asset, applies the Linux wrapper, and runs the derivation's existing `omp --version` install check.

## Completion policy

Delete `_carapace.nix` and the Nushell conditional that writes `carapace/specs/omp.yaml`.

OMP provides generated completions for Bash, Zsh, and Fish, but not Nushell. The current module already installs generated Bash and Fish completions; their output is generated from the packaged binary at build time and needs no release-specific maintenance.

Nushell receives no OMP-specific static completion specification. This is an intentional trade-off: OMP behavior and version updates no longer depend on manually synchronizing a third-party completion schema.

## Error handling and safety

- The updater changes no repository file until all release metadata checks pass.
- The JSON write is atomic; a failed API request or validation leaves the pinned release unchanged.
- A failed native build leaves the updated release data available for inspection and correction; it does not claim success.
- The updater does not deploy Home Manager configurations or run upstream `omp update`.

## Verification

Implementation must demonstrate:

1. Exact-version and latest-release modes produce valid release data for a known release.
2. Draft, prerelease, incomplete-asset, and digest-less release metadata are rejected without modifying the data file.
3. `nix build .#oh-my-pi` succeeds after updating on native Linux, proving binary download integrity, ELF/wrapper setup, and `omp --version` startup.
4. Nushell no longer receives the Carapace OMP spec; Bash and Fish completion derivations continue to evaluate.

## Non-goals

- Scheduled or automatic OMP updates.
- Changing to Bun, mise, curl-installer, Homebrew, source builds, or another package source.
- Executing or emulating non-native platform binaries locally.
- Creating a generic updater framework for unrelated packages.
