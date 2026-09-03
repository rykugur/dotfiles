# Vasher Prebuild Monitor Design

**Date:** 2026-09-02

**Status:** Approved.

## Purpose

The Vasher prebuild monitor protects unattended candidate builds from resource exhaustion and silent stalls. It records all observations and actions in the Vasher ledger.

The monitor uses fixed rules for recovery actions. A remote low-cost model explains important events, but the model cannot control Vasher.

## Context

Vasher has 12 GiB of RAM and 2 GiB of swap. A cold Jezrien build previously filled both resources and made Vasher unresponsive.

The build worker runs below `nix-daemon.service`. Therefore, the candidate service does not contain all build resource use.

The current prebuild script already provides these functions:

- A serialized prebuild lock.
- Status, history, and log files below `/var/lib/vasher/dashboard`.
- Garbage collection before a build and after a handled error.
- A retained GC root for the latest successful candidate.
- A SOPS-managed GitHub token for flake updates.

## Goals

The monitor has these goals:

1. Detect dangerous memory, swap, and disk conditions before Vasher becomes unresponsive.
2. Detect a build that has no useful activity for a long interval.
3. Stop an unsafe build, collect garbage, and retry the same candidate once.
4. Prevent retry loops across monitor or host restarts.
5. Record events, actions, and model summaries in the existing ledger.
6. Keep all recovery decisions deterministic and testable.
7. Prevent the monitor from using SSH to any host.

## Non-goals

The monitor does not change Nix build concurrency or the Vasher resource envelope. It does not promote a candidate or change Jezrien.

The monitor does not discover hosts, inspect other machines, or expose a remote-control endpoint. It does not send chat, email, or push notifications.

The model does not select commands, thresholds, retry behavior, or service actions. The model does not receive tools.

## Components

### Prebuild script

The existing prebuild script creates a candidate commit before the build starts. The commit contains the updated `flake.lock` and OMP release file.

The script writes the candidate revision to `status.json` before it starts `nix build`. This revision is the durable attempt identifier.

A retry mode accepts an expected candidate revision. This mode verifies the existing detached worktree before it builds the same commit.

The retry mode does not fetch Git, update the flake, or run the OMP updater. A mismatch stops the retry and records `needs-attention`.

### Monitor service

`vasher-prebuild-monitor.service` runs one fixed monitor program. The program samples local state every 30 seconds while the candidate service is active.

The monitor reads these local sources:

- `vasher-prebuild-candidate.service` state and CPU use.
- `nix-daemon.service` CPU and memory use.
- `/proc/meminfo` and `/proc/pressure/memory`.
- Filesystem statistics for `/`.
- The Vasher status file and current log.
- The durable monitor state file.

The monitor writes `/var/lib/vasher/monitor/state.json` with atomic replacement. The file stores the candidate revision, recovery phase, and retry count.

### Model client

The monitor uses a fixed HTTPS client for the OpenRouter Chat Completions API. The client uses `deepseek/deepseek-v4-flash` with a maximum output of 512 tokens.

The API key uses the SOPS secret `swoleflake/openrouter_api_key`. The monitor reads the key from its secret file into process memory.

The client sends requests only to `https://openrouter.ai/api/v1/chat/completions`. Each request has a 30-second timeout and no tool definitions.

The model client cannot select a URL from configuration, log text, or model output. An inference error never blocks deterministic recovery.

### Ledger

The monitor stores events in `/var/lib/vasher/dashboard/events.json`. The file keeps the newest 100 events.

Each event has these fields:

- `id`
- `timestamp`
- `revision`
- `type`
- `severity`
- `reason`
- `metrics`
- `action`
- `summary`
- `inferenceError` when a summary request fails

The ledger frontend shows the event timeline with the existing status and history views. The web server exposes the event file as read-only JSON.

## Resource rules

The monitor samples each rule every 30 seconds. A transient sample does not cause a recovery action.

### Memory rule

The memory rule becomes active after either condition lasts for 120 seconds:

- `MemAvailable` is less than 768 MiB.
- `SwapFree` is less than 256 MiB.

The event includes host memory, host swap, memory pressure, and Nix daemon memory. The monitor stops the candidate service after the rule becomes active.

### Disk rule

The disk rule becomes active when free space on `/` is less than 5 GiB for 60 seconds. The monitor then stops the candidate service.

### Stall rule

The stall rule becomes active when both conditions last for 30 minutes:

- The current build log does not increase in size.
- Combined CPU use increases by less than 10 CPU-seconds.

Combined CPU use includes the candidate service and `nix-daemon.service`. This rule detects idle waits without stopping a slow active compiler.

### Recovery preconditions

After a stop, the monitor waits until the candidate service is inactive.

The monitor then runs the existing workflow-local garbage collection. The monitor starts one retry only when all conditions are true:

- `MemAvailable` is at least 2 GiB.
- `SwapFree` is at least 1 GiB.
- `nix-daemon.service` memory stays less than 2 GiB for 60 seconds.
- Free space on `/` is at least 10 GiB.
- The detached worktree matches the recorded candidate revision.
- The retry count for the candidate revision is zero.

If a condition is false, the monitor records `needs-attention` and does not retry.

## Recovery state machine

The durable state machine has these states:

1. `observing`
2. `stopping`
3. `cleaning`
4. `retrying`
5. `complete`
6. `needs-attention`

A candidate starts in `observing`. A sustained resource or stall rule changes the state to `stopping`.

After the service stops, the state changes to `cleaning`. Successful cleanup and valid preconditions change the state to `retrying`.

The monitor increments the durable retry count before it starts the retry. Therefore, a process or host restart cannot start a second retry.

A successful retry changes the state to `complete`. A second unsafe condition, retry error, or invalid precondition changes the state to `needs-attention`.

An ordinary build error does not cause an automatic retry. The prebuild script records the error and runs its existing garbage collection.

## Inference events

The monitor requests a model summary after these events:

- A safety stop.
- An ordinary build error.
- A successful build.
- A final `needs-attention` result.

The evidence bundle contains the revision, rule state, resource samples, action history, exit code, timestamps, and a bounded log tail.

The log tail has a limit of 200 lines and 32 KiB. The client removes known authorization headers, tokens, secret values, and credential query parameters.

The model returns plain explanatory text. The monitor stores this text in the event `summary` field without parsing it as instructions.

Model text cannot enter a command, unit name, file path, URL, threshold, or state transition. The frontend displays the text as escaped content.

## Security boundary

The monitor has no SSH capability. Its runtime closure does not include OpenSSH, an SSH library, or an SSH agent client.

The systemd service denies access to home directories and SSH sockets. It cannot read the Vasher deploy key or any user SSH key.

The monitor does not scan the network. It does not connect to any private network address.

The only remote operation is the fixed HTTPS request to the OpenRouter API. All systemd and Nix actions target the local Vasher host.

The service uses systemd hardening with a read-only system. It receives write access only to the monitor and dashboard state directories.

The service has no Linux capabilities. It uses local systemd control for these allowlisted actions only:

- Stop `vasher-prebuild-candidate.service` or `vasher-prebuild-retry.service`.
- Run the prebuild cleanup operation.
- Start the prebuild retry operation for the recorded revision.

The program constructs each action from fixed strings. It never passes model or log text to a shell.

## Error handling

If status data is invalid, the monitor records a local error and takes no recovery action. The next sample can clear the error.

If cleanup fails, the monitor records `needs-attention` and does not retry. If inference fails, the monitor records the API error without the secret value.

If the monitor restarts, it reads the durable state before it observes services. It resumes only the fixed transition that matches actual local state.

If Vasher reboots during recovery, the monitor does not restart a candidate automatically. It records `needs-attention` for operator review.

## Tests

The tests use fake systemd, cgroup, filesystem, clock, and model interfaces. They do not contact OpenRouter or start a real Nix build.

The tests must make sure that:

1. Each resource rule requires the complete persistence interval.
2. Log activity or CPU activity prevents the stall rule.
3. A safety stop occurs before cleanup.
4. Cleanup occurs before a retry.
5. The retry builds the recorded candidate revision without another update.
6. One candidate revision receives no more than one automatic retry.
7. A monitor restart keeps the retry count and recovery state.
8. Failed recovery preconditions produce `needs-attention`.
9. An ordinary build error does not cause an automatic retry.
10. Inference errors do not change deterministic recovery.
11. Model output cannot cause commands or state changes.
12. The evidence bundle removes representative secret formats.
13. The frontend escapes model output.
14. The monitor runtime and code contain no SSH execution path.

A Nix evaluation must make sure that the service closure excludes OpenSSH. A local smoke test must operate the state machine with fake inputs.

## Acceptance criteria

The feature is complete when all conditions are true:

- The monitor records candidate progress without continuous inference.
- The monitor stops a simulated unsafe build after the specified persistence interval.
- The monitor collects garbage and retries the same candidate once.
- The monitor never starts a second retry for that candidate.
- The ledger shows the trigger, metrics, actions, model summary, and final result.
- A model or API error cannot prevent recovery.
- No monitor code path uses SSH or connects to another private network host.
- Existing prebuild success, failure, GC-root, and promotion behavior remains unchanged.
