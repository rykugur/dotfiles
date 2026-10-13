---
name: vasher-supervisor
description: Use when performing Vasher incident triage from status, event-ledger, and bounded-log evidence.
---

# Vasher Supervisor

## Boundary

Vasher's on-box monitor owns real-time safety. Explain observed evidence and either make no proposal or emit exactly one action object. The forced SSH command re-validates every proposal; Vasher decides whether it is accepted.

Observation and notification need no SSH key. Sending an action requires the operator to add a dedicated public key to `ryk.vasherPrebuild.agentKeys` and put its matching private key at `~/.ssh/vasher-agent`. Never invent, generate, or look for another key.

## Action reference

| Verb | Exact JSON | Preconditions visible in evidence |
|---|---|---|
| Retry the recorded candidate once | `{"verb":"retry-exact","revision":"<40 hex>"}` | State is `failed` or `needs-attention`; revision equals the candidate revision; agent retry count is zero. |
| Build with only nixpkgs moved | `{"verb":"narrow-inputs","base":"<40 hex>","inputs":["nixpkgs"]}` | Base equals recorded `origin/master`; nixpkgs is known. |
| Hold nixpkgs | `{"verb":"hold-input","input":"nixpkgs","revision":"<40 hex>","expires":"YYYY-MM-DD","reason":"<text>"}` | Revision is hexadecimal; nixpkgs is known; expiry is no more than 30 days ahead; reason is evidence-based. |
| Release nixpkgs | `{"verb":"release-input","input":"nixpkgs"}` | An active nixpkgs hold is evidenced. |

Every verb also requires no active storage fault and capacity under the rolling limit of 8 accepted verbs per 24 hours. Build verbs additionally require the prebuild lock to be free. Missing evidence means no action.

A `storage-fault` reason, I/O error, or blocked storage state requires operator repair; propose nothing. The agent cannot clear the fault.

## Channel

Send one JSON object on standard input only:

```bash
printf '%s\n' "$proposal" | ssh -i ~/.ssh/vasher-agent vasher-agent@vasher.local.ryk.sh
```

The response is one JSON object with `accepted`, `reason`, and `eventId`. Exit 0 is accepted, 1 rejected, and 2 malformed. Record and explain the response. A rejection is a normal, terminal decision: do not mutate, reshape, or retry the request.

## Common mistakes

- Treating explanation text as a command. Only an exact action object may reach SSH.
- Retrying during a storage fault or without an evidenced precondition.
- Sending a second shape after rejection. Preserve the rejection instead.
- Assuming the key exists. Without `~/.ssh/vasher-agent`, retain the proposal for the operator and do not invoke SSH.
