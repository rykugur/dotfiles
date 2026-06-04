# Swoleflake LLM Wiki — Log

Append-only chronological record. Entries use the machine-friendly prefix `## [YYYY-MM-DD] <verb> | <title>`.

---

## [2026-06-03] init | Bootstrapped llm-wiki structure and core pages

- Created `wiki/` with `raw/`, `concepts/`, `entities/`, `sources/` subdirs.
- Wrote `wiki/schema.md` (domain-specific instructions, workflows, Nix/Swoleflake conventions, mempalace notes).
- Wrote `wiki/raw/README.md` (guidance for the immutable source layer).
- Synthesized initial core pages by surveying the repo:
  - `overview.md`
  - `architecture.md`
  - `hosts.md`
  - `modules.md`
  - `history.md`
  - `ai-agents.md`
- Created `index.md` (catalog) and this `log.md`.
- All pages include frontmatter, relative cross-links, and pointers back to raw sources (CLAUDE.md, README, design docs, flake.nix, module files).
- The wiki now provides a persistent synthesized view of the dendritic flake, hosts, module system, migration history, and especially the AI agent provisioning (which distributes the llm-wiki skill itself).

This establishes the three layers:
- Raw (starting guidance + future drops)
- Wiki (the generated pages above)
- Schema (the rules in schema.md)

Future work will be driven by actual ingest of the superpowers design docs (deeper dives), code changes, user questions, and periodic lint passes.

## [2026-06-03] ingest | 2026-03-23 Dendritic Module Conversion design spec

- Created `wiki/sources/2026-03-23-dendritic-module-conversion.md` with faithful summary of the key decisions (no enable opts, import=activation, domain categories, cross-class modules, auto-discovery).
- Updated [history.md](history.md) to cross-reference the new source page and note it as primary literature.
- Updated [index.md](index.md) to list the new source summary under Sources.
- This serves as the first concrete "ingest one source → touch multiple pages" example for the wiki.

## [2026-06-03] update | Supporting integration changes for new wiki

- Added "wiki" room to root `mempalace.yaml` so the memory palace tool knows about the curated knowledge base (complements the llm-wiki skill).
- Added a "LLM Wiki (knowledge base)" section to root `CLAUDE.md` so coding agents are directed to use `wiki/index.md` + `wiki/schema.md` when relevant.
- Populated `wiki/concepts/README.md` and `wiki/entities/README.md` so the category directories are useful and git-trackable.
- These changes were made as part of the initial creation pass.

---


