# Vasher Agent Supervision Design

**Date:** 2026-10-12

**Status:** Draft.

## Purpose

Vasher builds the Jezrien closure without an operator. The prebuild monitor keeps the host safe during a build. The monitor cannot choose a smaller set of flake inputs, hold a broken input, or tell the operator that a build needs attention.

This design adds a narrow action channel on Vasher and a supervisor role for the Hermes agent on Jezrien. Hermes watches Vasher over the existing read-only HTTP endpoint. Hermes sends a small number of typed actions through the channel. Vasher validates every action and runs it with the existing prebuild script.

The monitor keeps all real-time safety duties. The agent never holds Vasher's Git credentials and never gets a shell on Vasher.

## Context

The current pipeline works like this. A refresh timer runs 15 minutes after each prior completion and exits as `idle` when `cache-bump` already covers `origin/master`. A candidate timer runs at 03:00 with up to 10 minutes of random delay. The candidate flow updates all flake inputs, runs the Oh My Pi updater, builds the reduced Jezrien closure, and force-with-lease pushes `cache-bump`. An operator promotes the candidate by hand with `scripts/vasher-promote.sh`.

`vasher-prebuild-monitor.service` samples local state every 30 seconds. It stops an unsafe build, collects garbage, and retries the same candidate one time. It writes a ledger to `/var/lib/vasher/dashboard/events.json`. It sends a sanitized evidence bundle to a remote model for an explanation. The model cannot control Vasher. The service has no SSH binaries, denies all private network addresses, and cannot read `swoleflake/deploy_key` or `swoleflake/github_token`.

Three gaps remain.

1. The candidate flow updates every flake input at once (`modules/nixos/vasher-prebuild.sh:153`). One broken input blocks every bump until an operator intervenes. No automatic fallback to a smaller input set exists.
2. No notification path exists. The monitor design forbids chat, email, and push. An operator finds a failure by opening the dashboard.
3. The monitor has no rule for storage faults. It samples free space only (`modules/nixos/vasher-prebuild-monitor.py:122-144`). The disk-full event of 2026-09-11 was later traced to a failing SSD, which is now under RMA. A failing disk presents as unexplained nix crashes, and the current response to a failed build can be a retry. A retry on a failing disk is the worst available response.

## Goals

1. Keep every real-time safety decision on Vasher, local, and deterministic.
2. Update a chosen subset of flake inputs on request.
3. Hold a broken input at a known-good revision for a limited time.
4. Stop all builds when the storage reports input or output errors, and require an operator to clear that state.
5. Report an incident to the operator without the operator opening the dashboard.
6. Keep the agent's credentials separate from Vasher's Git credentials.
7. Move `cache-bump` only after a successful build, for every action path.

## Non-goals

Promotion stays manual. The agent does not promote a candidate and does not change Jezrien.

The agent does not receive a shell on Vasher, an SSH path from Vasher to any host, or read access to the deploy key or the GitHub token.

The agent does not change monitor thresholds, the retry budget, Nix build concurrency, or the Vasher resource envelope.

The monitor does not call the agent. The agent polls Vasher.

This design adds no public endpoint. All new network paths stay inside the trusted LAN.

## Components

### Hold list

The hold list is a single file at `/var/lib/vasher/agent/holds.json`. It maps a flake input name to a hold record. Each record contains `revision`, `expires`, `reason`, and `createdAt`.

The action channel program is the only writer of this file. The prebuild script reads the file. This keeps one writer and avoids a lock.

A hold expires at most 30 days after creation. The prebuild script ignores an expired hold and an unknown input name. The dashboard shows an expired hold as expired, so no separate expiry event is needed.

The directory `/var/lib/vasher/agent` is mode 0755 and owned by `vasher-agent`. Both `holds.json` and `narrow-request.json` are mode 0644, so the `vasher` user can read them without a group membership. The file `verbs.json` is mode 0600, because only the channel program reads it.

### Input selection in the candidate flow

The candidate flow gains one step before the update. The script reads the input names from `nix flake metadata --json` on the worktree. It removes every input that has an active hold. It then runs `nix flake update` with the remaining names as positional arguments.

Nix 2.34 is the version on Vasher. The positional form updates only the named inputs. When the hold list is empty, the script passes no names, and `nix flake update` updates every input. Therefore the behavior with no holds is identical to the behavior today.

### Narrow candidate mode

The prebuild script gains a `narrow` mode. The mode reads a request file at `/var/lib/vasher/agent/narrow-request.json` that contains `base` and `inputs`.

The mode builds a candidate from `base` with only the named inputs updated, minus any held input. It does not run the Oh My Pi updater, because a narrow build is a recovery action that must change only what the request names.

After the update, the mode follows the existing path without change. It commits `flake.lock`, builds the target attribute, retains a GC root, confirms that `origin/master` still matches the base revision, and force-with-lease pushes `cache-bump`. A failed build leaves `cache-bump` unchanged.

`vasher-prebuild-narrow.service` runs this mode as the `vasher` user with the same hardening as the other prebuild units.

### Action channel

`vasher-agent-verb` is a fixed program that reads one JSON object from standard input. The maximum request size is 4 KiB. The program ignores `SSH_ORIGINAL_COMMAND`.

A new system user `vasher-agent` owns the channel. The SSH key of the supervisor appears in the authorized keys of that user with a forced command and the `restrict` option:

```
command="vasher-agent-verb",restrict ssh-ed25519 AAAA... hermes@jezrien
```

A new option `ryk.vasherPrebuild.agentKeys` holds the list of public keys. The operator keys in `modules/hosts/vasher/_ssh.nix` stay separate and keep their normal root access.

The channel accepts four verbs and rejects everything else:

```json
{"verb": "retry-exact",    "revision": "<40 hex>"}
{"verb": "narrow-inputs",  "base": "<40 hex>", "inputs": ["nixpkgs", "home-manager"]}
{"verb": "hold-input",     "input": "nixpkgs", "revision": "<40 hex>", "expires": "2026-11-01", "reason": "<text>"}
{"verb": "release-input",  "input": "nixpkgs"}
```

The program answers with one JSON object on standard output that contains `accepted`, `reason`, and `eventId`. Exit code 0 means accepted, 1 means rejected, and 2 means malformed input.

The program never passes request text to a shell. For a build verb it writes a request file atomically and starts one fixed unit name. A polkit rule permits the `vasher-agent` user to start exactly `vasher-prebuild-retry.service` and `vasher-prebuild-narrow.service`. The units run as `vasher` and read the secrets themselves. Therefore the channel user needs no access to any secret.

### Action preconditions

The program checks every condition before it accepts a verb. All conditions are deterministic.

1. The storage fault file does not exist. A storage fault rejects every verb.
2. The prebuild lock is free. A running build rejects every build verb with the reason `busy`.
3. `retry-exact` requires a recorded state of `failed` or `needs-attention`. The revision must equal the candidate revision in `status.json`. The agent retry count for that revision must be zero.
4. `narrow-inputs` requires a base that equals the current `origin/master` recorded in `status.json`. The input list must contain between 1 and 8 names. Every name must exist in the flake metadata.
5. `hold-input` requires an expiry date no more than 30 days ahead, a 40-character hexadecimal revision, and a known input name.
6. The channel accepts at most 8 verbs in a rolling 24-hour period.

Durable counters live in `/var/lib/vasher/agent/verbs.json`. The program writes the file atomically. A restart of the host keeps the counters.

The program writes one ledger event for every accepted verb and every metered rejection. Once the rejection window is exhausted, lockout probes are logged only to syslog so they cannot churn either ledger.

### Storage fault rule

After a candidate, narrow, or retry build exits with a failure, the monitor scans the captured log tail for these patterns:

- `Input/output error`
- `csum failed`
- `failed to read block`
- `blk_update_request`

A match writes `/var/lib/vasher/monitor/storage-fault.json` with the revision, the matched pattern, and the timestamp. The monitor sets the durable state to `needs-attention` with the reason `storage-fault`, severity critical. The monitor does not retry.

The prebuild script refuses to start any mode while that file exists. It records the status state `blocked` and exits with code 0, because a blocked timer run is not a build failure.

The agent cannot clear this state. An operator clears it after the disk is replaced:

```bash
sudo rm /var/lib/vasher/monitor/storage-fault.json
```

After a failed build, the monitor also reads `/sys/fs/btrfs/*/devinfo/*/error_stats` when the path is readable. An increase from the previous readable failed-build sample triggers the same state. Vasher is an unprivileged LXC, so this path can be absent. The rule applies only when the path exists, and the log scan covers the container case.

### Supervisor on Jezrien

The supervisor is a wrapper program named `vasher-supervise` and a Hermes skill. The wrapper does the deterministic work. Hermes does the explanation and chooses the verb.

The wrapper runs these steps:

1. Fetch `http://vasher.local.ryk.sh:5080/api/status.json` and `/api/events.json` with a 10-second timeout.
2. If Vasher does not answer on two consecutive runs, send a notification and exit 0.
3. Decide whether work exists. Work exists when the state is `failed`, `stale`, `needs-attention`, or `blocked`, or when the event list contains an identifier that is newer than the last recorded identifier.
4. If no work exists, exit 0 without a model call.
5. If work exists, run Hermes once with the skill, the evidence bundle, and the channel command available.

The wrapper keeps state in `~/.local/state/vasher-supervise/`. The file `last-seen.json` holds the last event identifier and the consecutive unreachable count. The file `digest.md` holds the most recent written summary.

The evidence bundle contains the status record, the newest three events, the exit code, and a log tail limited to 200 lines and 32 KiB. The wrapper removes authorization headers, tokens, secret values, and credential query parameters before the model call. These limits match the monitor design.

Hermes reaches the channel with a dedicated key at `~/.ssh/vasher-agent`:

```bash
ssh -i ~/.ssh/vasher-agent vasher-agent@vasher.local.ryk.sh
```

The skill lives at `modules/ai/skills/vasher-supervisor/SKILL.md` and installs through the existing local skill list in `modules/ai/_skills.nix`. The skill states the verb schema, the preconditions, and one rule: Hermes proposes a verb, and Vasher decides.

The wrapper writes the digest file on every model run and calls `notify-send` for severity warning and above.

### Trigger

`systemd.user.timers.vasher-supervise` on Jezrien runs the wrapper every 30 minutes. A second timer runs the wrapper with the `--digest` flag on Monday at 09:00, which always calls the model and always writes a summary of the week.

The wrapper is the unit of work. If the always-on Hermes service gains its own scheduler, that scheduler calls the same wrapper and the operator disables the timers. The contract does not change.

### Dashboard

`events.json` gains a `source` field with the value `monitor` or `agent`. An agent event also carries the verb name and the accepted flag. The frontend shows the source next to each event.

Caddy serves `/api/holds.json` as a read-only file in the same way it serves the existing four files. The frontend shows the active holds with their expiry dates. An expired hold appears as expired.

The state union in `modules/nixos/vasher-dashboard/src/main.tsx:7` gains the value `blocked`. The description function gains one line for that state, which names the fault file and the operator command that clears it.

## Security boundary

The monitor keeps its current boundary without change. It has no SSH path, it denies all private network addresses, and it cannot read the deploy key or the GitHub token.

The channel program runs as `vasher-agent`. That user is not a member of the `vasher` group and cannot read `swoleflake/deploy_key` or `swoleflake/github_token`, because both files are mode 0400 and owned by `vasher`.

The forced command removes port forwarding, agent forwarding, TTY allocation, and command selection. A client can send only a JSON object on standard input.

Model text cannot become a command, a unit name, a file path, a URL, or a threshold. The channel program builds every command from fixed strings and starts fixed unit names through polkit. The program re-validates every field, so a wrong or hostile proposal fails the same checks as a typo.

A build verb cannot publish a broken closure. Every path to `cache-bump` passes the existing build gate and the existing check that `origin/master` has not moved.

The supervisor key is separate from the operator keys. Revoking the supervisor means removing one entry from `ryk.vasherPrebuild.agentKeys`.

## Error handling

A malformed request, an unknown verb, or a failed precondition produces a rejection event and no action.

A model error or an inference timeout leaves the wrapper with no verb to send. The wrapper writes the digest with the raw evidence and exits 0. No deterministic behavior depends on the model.

An unreachable Vasher produces a notification after two consecutive failed runs. A single failed poll is silent, because a reboot or a short network loss is normal.

A storage fault blocks the pipeline until an operator clears it. The dashboard and the digest both show the blocked state and the matched pattern.

## Tests

The tests use fake HTTP, systemd, filesystem, clock, and model interfaces. They do not start a real Nix build and do not contact a remote model.

The tests must make sure that:

1. An empty hold list produces a `nix flake update` call with no input arguments.
2. An active hold removes exactly that input from the update call.
3. An expired hold and an unknown input name do not change the update call.
4. A hold with an expiry more than 30 days ahead is rejected.
5. Narrow mode updates only the requested inputs and skips the Oh My Pi updater.
6. A failed narrow build leaves `cache-bump` unchanged.
7. Each verb is rejected when its precondition fails, with the documented reason.
8. The channel rejects an unknown verb, oversized input, and malformed JSON with exit code 1 or 2.
9. The rolling limit rejects the ninth accepted verb in 24 hours and survives a restart.
10. A second `retry-exact` for the same revision is rejected.
11. Each storage-fault pattern in a failed log creates the fault file and blocks the next prebuild run.
12. The agent channel cannot remove the fault file.
13. The wrapper makes no model call when the state is `success` or `idle` and no new event exists.
14. The wrapper notifies only after two consecutive unreachable polls.
15. The evidence bundle removes representative secret formats.
16. A model error produces a digest and no verb.

A Nix evaluation must make sure that the `vasher-agent` user is not a member of the `vasher` group, and that the polkit rule names exactly two units.

A smoke test must send one real `hold-input` verb over SSH to a live Vasher, confirm the ledger event and `/api/holds.json`, and then release the hold.

## Acceptance criteria

The feature is complete when all conditions are true:

- A held input stays at its recorded revision through a nightly candidate run, and the run updates the other inputs.
- A `narrow-inputs` verb produces a candidate that moves only the named inputs, and `cache-bump` moves only after that build succeeds.
- The channel rejects every malformed, unauthorized, out-of-budget, and precondition-violating request, and records each rejection.
- A simulated I/O error in a build log blocks all further builds until an operator removes the fault file.
- The supervisor makes no model call during a healthy day, and reports a failure to the desktop within 30 minutes.
- No new code path gives the agent a shell on Vasher, access to the deploy key, or the ability to promote a candidate.
- Existing refresh, candidate, monitor recovery, GC-root, and promotion behavior stays unchanged when the hold list is empty and no verb arrives.
