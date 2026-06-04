# Raw Sources for Swoleflake LLM Wiki

This directory holds immutable source documents that feed the wiki.

## Guidelines

- Drop new external articles, notes, transcripts, design drafts here as `.md` files (use Obsidian clipper + download images for web content).
- For internal repo evolution: when a major change lands, create a source card here that captures the "what changed" + link to the PR/diff or the design doc in `docs/superpowers/`.
- The LLM (when ingesting) reads files here **but never edits them**. Synthesis, cross-refs, and updates go into sibling wiki pages only.
- Snapshots: if desired, copy key historical files (e.g. a design spec) here at ingest time so the wiki can refer to exact version that informed a decision.

## Current primary sources (live repo, not copied here yet)

The wiki treats the following as canonical live sources (read via tools or cat in context):

- Root: README.md, CLAUDE.md, flake.nix, flake.lock, mempalace.yaml, DENDRITIC_MIGRATION.md, justfile
- docs/superpowers/{plans,specs}/*.md — historical design artifacts and migration plans (the "superpowers" that shaped current form)
- modules/ tree (all .nix)
- hosts/*/ 
- configs/
- overlays/, pkgs/, shells/, scripts/
- legacy-modules/ (for archaeology)

When a design doc is particularly pivotal, a copy or excerpt may be placed in this raw/ dir.

## Tools

- Use `mempalace` (via MCP or CLI) in conjunction for working memory / rooms.
- The llm-wiki skill (this pattern) governs how we maintain the synthesized layer.

See `../schema.md` for full conventions.
