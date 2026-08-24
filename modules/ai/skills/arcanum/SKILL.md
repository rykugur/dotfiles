---
name: arcanum
description: Use before starting non-trivial work on ~/projects/homelab, ~/projects/dotfiles, or other tracked infra/AI projects, and whenever the user asks "have we dealt with this before" / "what do we know about X" / references past decisions, architecture, or troubleshooting. Check the Arcanum knowledge base via the arcanum MCP tools (query/get/status) before re-deriving an answer or re-investigating something that may already be documented.
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
  `wiki/Reference/Slow-Steam-Downloads.md`'s multi-pass investigation history:
  checking first would have skipped a retired, wrong theory).
- Before making a non-trivial change to `~/projects/homelab` or
  `~/projects/dotfiles` — check for prior decisions/conventions that constrain
  the change (see `[[conventions]]`, `[[architecture-overview]]`-style pages).
- Whenever the user references "we", "before", "last time", "already", or
  otherwise implies continuity with past work.
- Before answering "what do you know about X" for X = a project, host,
  service, or recurring topic tracked in the wiki.

## How to use it

Three read-only tools, no auth, LAN-only endpoint:

- `query` — hybrid BM25 + semantic + reranked search. Best first move for a
  fuzzy question. Provide `intent` on every call. Expect **30-90s latency**
  on this deployment (N95 iGPU-accelerated reranker) — that's normal, not a
  hang; the client timeout here is tuned to 90s specifically for this.
- `get` — exact retrieval by path or docid from a `query` hit. Supports fuzzy
  path suggestions if you get the slug slightly wrong.
- `status` — index health/doc counts; fast, useful sanity check.

Always cite the returned repo-relative path when you use a result. If a
result contradicts something you're about to claim from memory, trust the
wiki — it's the corrected, cross-checked version.

## What it is not

Read-only. No mutation, shell, or write tools are exposed here — don't expect
to file new findings back through MCP. If a session produces something worth
keeping (a root cause, a corrected theory, a new convention), that's a
separate step: edit the wiki directly under `~/projects/arcanum` (if present
in the workspace) and push — git-sync picks it up on the homelab side within
~60s, no redeploy needed.
