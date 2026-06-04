---
title: Schema & Instructions
category: core
date: 2026-06-03
tags: [schema, instructions, llm-wiki]
sources: ["modules/ai/skills/llm-wiki/SKILL.md", "CLAUDE.md"]
related: ["overview.md", "index.md", "log.md"]
---

# Swoleflake LLM Wiki — Schema

This file is the **schema** layer for the LLM Wiki of the Swoleflake dotfiles repository (NixOS + nix-darwin multi-host configuration managed as a flake).

It tells any LLM agent (Claude Code, Codex, opencode, Pi, etc. when the `llm-wiki` skill is active) exactly how this particular wiki is structured, what conventions to follow, and the workflows for ingest / query / maintenance.

The high-level pattern comes from the [llm-wiki skill](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) (also vendored in this repo at `modules/ai/skills/llm-wiki/SKILL.md`). This schema specializes it for the Nix configuration domain.

## Core Principle

The wiki is a **persistent, compounding, LLM-written artifact** that sits between the human/agent and the raw source material (Nix code, historical design docs, configs). 

Knowledge is **compiled once** into interconnected pages and then kept current. Future questions and changes update the wiki rather than forcing re-discovery from raw files every time.

You (the LLM) own writing and bookkeeping. The user owns curation and direction.

## Directory Layout

```
wiki/
├── raw/                 # IMMUTABLE sources only. Never edit contents here.
│   ├── README.md        # This explains the raw layer (you are here in spirit)
│   └── ...              # .md files dropped for ingestion (articles, specs, cards)
├── concepts/            # Abstract ideas, patterns, philosophies (module system, dendritic, groups, etc.)
├── entities/            # Concrete named things (jezrien.md, taln.md, specific big modules)
├── sources/             # Per-source summary / analysis pages (one per major ingested artifact)
├── index.md             # REQUIRED: content-oriented catalog. Read this FIRST on any wiki-related task.
├── log.md               # REQUIRED: append-only chronological record. Machine-grep friendly.
├── schema.md            # This file. Evolves with the wiki.
├── overview.md          # High-level what/why/hosts/build commands.
├── architecture.md
├── hosts.md
├── modules.md
├── ai-agents.md         # The sophisticated AI provisioning in this repo (meta!)
├── history.md           # The story of how we got here (dendritic migrations etc.)
└── ...                  # Other pages as they emerge (e.g. gaming.md, secrets.md)
```

- Prefer **kebab-case.md** for filenames.
- Small wiki: mostly flat + the three category subdirs above. Split into more subdirs only when it clearly helps navigation.
- All pages are tracked in git. The wiki *is* part of the repo.

## Page Anatomy (Frontmatter + Content)

Every wiki page **must** begin with YAML frontmatter:

```yaml
---
title: Human Readable Title
category: core | concept | entity | host | module | migration | ai | source | other
date: 2026-06-03                  # creation or last major rewrite
tags: [nix, flake, hyprland]     # freeform, useful for Dataview/mental search
sources: ["CLAUDE.md", "docs/superpowers/specs/2026-03-23-....md", "flake.nix"]
related: ["architecture.md", "modules.md"]
---
```

Then:

# Title

One-paragraph **executive summary** (the most important 3-5 sentences).

## Key Facts

- Bullet list of durable truths.

## ...

Use `##` sections.

### Cross-references

At the bottom or in a dedicated section, list bidirectional links to other wiki pages using standard Markdown:

- [Architecture](architecture.md)
- [jezrien](entities/jezrien.md)

When you update a page, scan for pages that should now link *to* it and update them (or note in the log that a follow-up lint is needed).

**Code snippets**: Keep tiny and illustrative. Never paste large chunks of Nix that will go stale. Always prefer "see `modules/foo/bar.nix:123`" or "the pattern is `lib.mkEnableOption` + `mkIf config....enable`".

## Essential Files & Their Jobs

- **index.md**: The single source of truth for "what pages exist and what they contain at a glance". 
  - Organized by category sections.
  - Each entry: `- [Title](file.md) — one-line summary. (sources: N)`.
  - You read `index.md` before almost any other wiki file when answering questions.
  - Update it on *every* ingest or significant edit.

- **log.md**: Timeline. Append-only.
  - Format strictly: `## [2026-06-03] <verb> | <short title>`
    - Verbs: `init`, `ingest`, `update`, `query`, `lint`, `refactor`
  - Example: `## [2026-06-03] init | Bootstrapped wiki with core pages from repo survey`
  - This format lets `grep "^## \[" log.md | tail -10` work perfectly.
  - After a query that produced a valuable new page, log it and link the result page from index.

- **schema.md**: This document. When you discover a better convention while working, propose an update to this file (and do it if the user agrees).

## Operations

### Ingest (new knowledge arrives)

Typical sequence (adapt to size):

1. Source appears in `raw/` (or user says "ingest the changes in modules/ai after the pi addition").
2. Fully read the source (use tools: read_file, grep, etc.).
3. Extract takeaways. If unclear, note questions but still integrate what you can.
4. Create `sources/<kebab-of-source>.md` with a faithful summary + key excerpts + implications for the wiki.
5. Touch every page the new info affects:
   - Update `overview.md` / `architecture.md` if global.
   - Update or create entity pages.
   - Strengthen concept pages.
   - Revise history.md when the source is a migration artifact.
6. Run a mini-lint on affected area: add missing cross-refs, fix contradictions.
7. **Update index.md** (add the new source page, revise any one-line summaries that changed, bump "last updated").
8. Append a log entry.
9. Tell the user what was created/updated and offer to open key files or show a diff of changes.

A single good source can legitimately touch 5–15 wiki pages.

### Query / Answer

1. **Read `index.md` first** — this is non-negotiable for good results.
2. Select and read the 2–N most relevant pages.
3. Synthesize an answer.
4. Cite by name + link to the wiki pages used (not raw sources directly, unless the page is a source summary).
5. If the synthesis is non-trivial and likely useful later, **file it back into the wiki** as a new page (or section) and update index + log. Example outputs that should become pages: architecture comparisons, "how to add a new host" runbook, "current state of AI agents matrix".

Good answers compound the knowledge base.

### Lint & Health

Do this after big ingests or every ~10 new sources / monthly:

- Orphan detection: pages with zero inbound links (use grep for markdown links + index).
- Stale claims: anything asserting "current" behavior that a newer migration doc contradicts.
- Gaps: important concepts mentioned in several places but lacking their own page.
- Inconsistency: two pages saying different things about the same module or host.
- Suggestions: "We should add a page on X because Y keeps coming up."

The LLM is excellent at this bookkeeping.

## Domain-Specific Notes for Swoleflake

**What this wiki is about**:
- The declarative configuration system itself (not end-user apps inside the configs).
- How modules compose, the dendritic philosophy (fine-grained, auto-discovered modules), host wiring, groups.
- History of major refactors (the "superpowers" plans & specs in `docs/superpowers/` are gold).
- The AI agent layer (`modules/ai/*`) — this is unusually sophisticated and self-referential (the wiki skill and mempalace are managed here).
- Secrets (sops-nix), custom packages, overlays, home-manager patterns.
- Cross-platform (linux + darwin) concerns.

**What it is not** (avoid bloat):
- Full inventory of every single .nix file (use `modules.md` high-level map + `entities/` for the important ones only).
- User-facing app config details (those live in `configs/` and are "data").
- Transient debugging notes.

**Key patterns to highlight and keep consistent**:
- `lib.mkEnableOption` + `mkIf config.<opt>.enable`
- `import-tree` auto-loading with `_` prefix to opt-out
- Groups (`modules/groups/`) as the cross-platform feature composition layer (replaced legacy roles/)
- Per-host in `modules/hosts/<name>/` (with `_` files private)
- Special args passed down: `inputs`, `outputs`, `hostname`, `username`
- Home-manager as a module, not standalone
- sops-nix per-host secrets
- AI agents all wired through home-manager modules that consume shared `_agents.nix` + `_mcp.nix`

**Cross-reference the live docs**:
- Root `CLAUDE.md` and `README.md` are the "operator manual". The wiki can quote or link their build sections but should not duplicate them verbatim forever — point to them.
- When build commands or high-level overview drift, the wiki's overview must be reconciled with them.

**Mempalace integration**:
- `mempalace` (MCP + CLI) + the rooms in root `mempalace.yaml` provide dynamic, queryable "working memory" partitioned by area of the repo ("wing: dotfiles", rooms for modules, configs, etc.).
- This wiki is the **curated, synthesized, slower-changing layer** with history and rationale.
- They are complementary. When answering, you may use both (mempalace for fresh context or specific room facts; wiki for big-picture and "why").

**Self-reference**:
Because this repo *manages* the llm-wiki skill itself (see `modules/ai/skills/llm-wiki/`, `claude-code.nix`, `pi.nix` etc.), the wiki should eventually have a good page on "how the wiki skill is distributed and activated".

## File Hygiene & Git

- The wiki dir is committed.
- Do not put secrets or large binaries in it.
- `raw/assets/` (if images arrive) can be used; configure Obsidian attachment path accordingly if using it for browsing.
- When you edit, the changes are normal git diffs — user can review.

## Evolving This Schema

This schema is not sacred. As the wiki grows to dozens of pages you will discover what works and what doesn't for this domain. Update this file, add a log entry, and (important) update any pages that the convention change affects.

Example future evolutions:
- Adding a `decisions/` folder for Architecture Decision Records (ADRs) extracted from specs.
- Adding Dataview queries once frontmatter is rich.
- Adding a small search helper script in `wiki/tools/`.
- Splitting sources/ into finer categories.

## Quick Reference for Agents

When the user says anything like "update the wiki", "ingest this", "what does the wiki say about X", "lint the wiki":

1. `read_file` (or equivalent) `wiki/index.md` and `wiki/schema.md` and `wiki/log.md` (recent entries).
2. Proceed according to the workflows above.
3. Make the edits using your file tools.
4. Always leave the index and log in a consistent state.
5. Summarize the net effect for the user.

Now go maintain the knowledge.

---

*This schema was written as part of the initial wiki bootstrap on 2026-06-03.*
