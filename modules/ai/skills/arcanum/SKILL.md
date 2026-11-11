---
name: arcanum
description: Use before starting non-trivial work on ~/projects/homelab, ~/projects/dotfiles, or other tracked infra/AI projects, and whenever the user asks "have we dealt with this before" / "what do we know about X" / references past decisions, architecture, or troubleshooting. Check the Arcanum knowledge base at ~/projects/arcanum before re-deriving an answer or re-investigating something that may already be documented.
---

# Arcanum knowledge base

Arcanum (`github.com/rykugur/arcanum`) is a durable, LLM-maintained wiki that
accumulates knowledge across this user's AI/homelab/dotfiles work — root
causes of past incidents, architecture decisions, project notes, cross-linked
reference pages. It exists specifically so the same investigation doesn't get
redone from scratch every session. Treat it as a first-class source, not an
optional extra.

## When to check it

- Before diagnosing an infra/networking/homelab problem — the root cause or a
  closely related one may already be written up (see e.g.
  `wiki/Reference/Slow Steam Downloads.md`'s multi-pass investigation history:
  checking first would have skipped a retired, wrong theory).
- Before making a non-trivial change to `~/projects/homelab` or
  `~/.dotfiles` — check for prior decisions/conventions that constrain
  the change (see `[[Homelab Conventions]]`, `[[Homelab]]`-style hub and
  convention pages under `wiki/Projects/<Name>/`).
- Whenever the user references "we", "before", "last time", "already", or
  otherwise implies continuity with past work.
- Before answering "what do you know about X" for X = a project, host,
  service, or recurring topic tracked in the wiki.

## How to use it

There is no search service. The `arcanum` MCP was scaled to zero on
2026-10-30 after measurement showed a semantic query cost >80s against 0.45s
for the BM25 index under it (`log/2026-10.md:7221`). `grep` is the index.

- **Decisions and history:** `grep "^## \[" ~/projects/arcanum/log/*.md` for
  headings, then read the matching entry by range. Never read a month log
  whole — `log/2026-10.md` is ~430 KB.
- **Durable pages:** `grep -ril <term> ~/projects/arcanum/wiki/`, or
  `index.md` to resolve a page by name.
- **Specs and plans:** `archive/specs/<project>/`, `archive/plans/<project>/`,
  by path.

Always cite the returned repo-relative path when you use a result. If a
result contradicts something you're about to claim from memory, trust the
wiki — it's the corrected, cross-checked version.

## Writing back

If a session produces something worth keeping (a root cause, a corrected
theory, a new convention), edit the wiki directly under `~/projects/arcanum`,
then commit and push. Other machines read Arcanum from Forgejo, so unpushed
work is invisible to them. See that repo's `CLAUDE.md` for the entry format
and the read budget.
