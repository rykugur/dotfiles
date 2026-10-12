# Vasher Agent Supervision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Vasher a hold list, a narrow-input build mode, a four-verb SSH action channel, and a storage-fault halt, then drive them from a Hermes supervisor on Jezrien.

**Architecture:** All authority stays in the existing deterministic programs. `vasher-prebuild.sh` gains input selection and a `narrow` mode. `vasher-prebuild-monitor.py` gains a storage-fault rule that blocks the pipeline. A new `vasher-agent-verb` program behind an SSH forced command validates four JSON verbs and starts fixed units through polkit. On Jezrien, a wrapper prefilters the existing read-only HTTP endpoints and calls Hermes only when an incident exists.

**Tech Stack:** Bash (prebuild script), Python 3 (monitor, verb program, tests), Nix (flake-parts modules via import-tree), React + TypeScript (dashboard), systemd, polkit, Caddy.

**Spec:** `docs/superpowers/specs/2026-10-12-vasher-agent-supervision-design.md`

## Global Constraints

- Repo is "swoleflake" at `~/.dotfiles`, flake-parts with import-tree. A NixOS module is `flake.modules.nixos.<name>`; a home-manager module is `flake.modules.homeManager.<name>`.
- Never run `nixos-rebuild switch`, `darwin-rebuild switch`, or `home-manager switch`. `nix build`, `nix eval`, and `nix flake check` are allowed.
- Nix on Vasher is 2.34. `nix flake update` with no positional arguments updates every input. With positional input names it updates only those inputs.
- Revisions are validated with `^[0-9a-f]{40}$`, the existing pattern in `vasher-prebuild.sh:128-133` and `vasher-prebuild-monitor.py:44`.
- Agent state directory: `/var/lib/vasher/agent`, mode 0755, owner `vasher-agent`. `holds.json` and `narrow-request.json` are mode 0644. `verbs.json` is mode 0600.
- Storage fault file: `/var/lib/vasher/monitor/storage-fault.json`.
- Maximum hold age is 30 days. Maximum narrow input count is 8. Maximum accepted verbs is 8 per rolling 24 hours. Maximum agent retries per candidate revision is 1.
- The channel accepts exactly four verbs: `retry-exact`, `narrow-inputs`, `hold-input`, `release-input`.
- `vasher-agent` must not be a member of the `vasher` group and must never read `swoleflake/deploy_key` or `swoleflake/github_token`.
- Model text must never become a command, unit name, path, URL, or threshold.
- Tests are standalone scripts under `scripts/tests/`, run directly. Bash tests stub binaries on `PATH` into a temporary directory (see `scripts/tests/test-vasher-prebuild-gc.sh`). Python tests use `unittest` and load the module under test with `importlib.util.spec_from_file_location` (see `scripts/tests/test-vasher-prebuild-monitor.py:16-22`).
- Commit messages use the existing style: `feat(vasher): …`, `fix(vasher): …`, `docs(vasher): …`.

## Review Focus

- A missing, empty, or malformed `holds.json` must leave the candidate flow exactly as it is today, because the file does not exist until the first `hold-input` verb arrives.
- A hold on an input name that no longer exists in `flake.nix` must not fail the nightly build, because inputs are renamed and removed over time.
- A `narrow-inputs` request whose input list is a subset of the held inputs must still produce a valid `nix flake update` call, because an empty remaining list means "update everything" and that is the opposite of the request.
- A verb that arrives while a build holds `prebuild.lock` must be rejected rather than queued, because two concurrent prebuild runs corrupt the shared worktree.
- An unreachable Vasher must not produce a notification on every single poll, because a reboot during the nightly window would otherwise notify every 30 minutes until morning.

---

### Task 1: Hold list and input selection

**Files:**
- Modify: `modules/nixos/vasher-prebuild.sh:145-164` (`prepare_updated_candidate`)
- Test: `scripts/tests/test-vasher-prebuild-holds.sh` (create)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: shell function `selected_inputs` that prints zero or more input names, one per line, for the caller to pass to `nix flake update`. Hold file path constant `HOLDS_FILE=/var/lib/vasher/agent/holds.json`. Hold record shape `{"<input>": {"revision": "<40 hex>", "expires": "YYYY-MM-DD", "reason": "<text>", "createdAt": "<iso8601>"}}`.

- [ ] **Step 1: Write the failing test** `scripts/tests/test-vasher-prebuild-holds.sh`

Follow the stub pattern in `scripts/tests/test-vasher-prebuild-gc.sh`: a temporary `PATH` directory with fake `git`, `nix`, and `nix-collect-garbage`, with the fake `nix` appending its full argument list to `$EVENTS` when `$1` is `flake` and printing a fixed JSON document when the arguments are `flake metadata --json`. The fixed document must describe four root inputs: `nixpkgs`, `home-manager`, `stylix`, `oh-my-pi`.

Assert these cases, each from a clean state directory:

```
no holds.json            -> recorded flake update call is exactly: flake update --flake <worktree>
empty object {}          -> same call as above
nixpkgs held, not expired-> call lists exactly home-manager, stylix, oh-my-pi (any order)
nixpkgs held, expired    -> same call as the no-holds case
unknown input held       -> same call as the no-holds case
malformed JSON           -> same call as the no-holds case
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `bash scripts/tests/test-vasher-prebuild-holds.sh`
Expected: FAIL, because `prepare_updated_candidate` always calls `nix flake update` with no input names.

- [ ] **Step 3: Implement `selected_inputs` in `modules/nixos/vasher-prebuild.sh`**

Add `HOLDS_FILE=/var/lib/vasher/agent/holds.json` beside the other path variables at the top of the script. Add `selected_inputs()` above `prepare_updated_candidate`. It prints nothing when the hold file is absent, unreadable, not valid JSON, or has no active hold. Otherwise it prints every root input name from `nix flake metadata --json --flake "$worktree"` that has no active hold. An active hold is one whose `expires` date is not before today, compared as `YYYY-MM-DD` strings. Use `jq` for both documents. Root input names come from `.locks.nodes.root.inputs | keys[]`.

Change the update call in `prepare_updated_candidate` to read the names into an array and pass them after `--flake "$worktree"`. An empty array yields the current command unchanged.

- [ ] **Step 4: Run the test to confirm it passes**

Run: `bash scripts/tests/test-vasher-prebuild-holds.sh`
Expected: PASS

- [ ] **Step 5: Confirm no regression in the existing prebuild tests**

Run: `bash scripts/tests/test-vasher-prebuild-gc.sh && bash scripts/tests/test-vasher-prebuild-retry.sh`
Expected: both PASS

- [ ] **Step 6: Commit**

```bash
git add modules/nixos/vasher-prebuild.sh scripts/tests/test-vasher-prebuild-holds.sh
git commit -m "feat(vasher): skip held flake inputs in the candidate flow"
```

---

### Task 2: Narrow candidate mode

**Files:**
- Modify: `modules/nixos/vasher-prebuild.sh:104-109` (mode dispatch), `:145-196` (candidate preparation and mode branch)
- Modify: `modules/nixos/vasher-prebuild.nix:134-148` (service definitions)
- Test: `scripts/tests/test-vasher-prebuild-narrow.sh` (create)

**Interfaces:**
- Consumes: `selected_inputs` from Task 1.
- Produces: mode `narrow` on `vasher-prebuild`, taking no positional arguments. Request file `/var/lib/vasher/agent/narrow-request.json` with shape `{"base": "<40 hex>", "inputs": ["<name>", ...]}`. Unit `vasher-prebuild-narrow.service`.

- [ ] **Step 1: Write the failing test** `scripts/tests/test-vasher-prebuild-narrow.sh`

Same stub pattern as Task 1. Assert:

```
valid request, 2 inputs      -> flake update call lists exactly those 2 inputs
                             -> the OMP updater script is never executed
                             -> status.json mode is "narrow"
request input also held      -> held name is removed, remaining names are still passed
every requested input held   -> script exits non-zero before calling nix build, status state "failed"
base != origin/master        -> script exits non-zero before calling nix build
request file missing         -> script exits 2
request base not 40 hex      -> script exits 2
nix build fails              -> no git push occurs
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `bash scripts/tests/test-vasher-prebuild-narrow.sh`
Expected: FAIL with `vasher-prebuild: unknown mode narrow`

- [ ] **Step 3: Implement the mode in `modules/nixos/vasher-prebuild.sh`**

Add `narrow` to the mode dispatch with blocking `flock 9`, the same as `candidate`. Add `prepare_narrow_candidate()` modeled on `prepare_updated_candidate`: it reads and validates the request file, validates `base` with `validate_revision`, requires `base` to equal the fetched `origin/master`, requires 1 to 8 input names that all exist in the flake metadata, subtracts active holds, and exits non-zero when no name remains. It resets the worktree to `base`, runs `nix flake update` with the remaining names, commits `flake.lock` only, and does not run `$OMP_UPDATER`. The worktree path for this mode is `/var/lib/vasher/worktrees/narrow`. Everything after preparation is the existing shared path.

- [ ] **Step 4: Add the unit in `modules/nixos/vasher-prebuild.nix`**

Add `vasher-prebuild-narrow = service "narrow";` to `systemd.services`. It takes no timer.

- [ ] **Step 5: Run the test and the evaluation check**

Run: `bash scripts/tests/test-vasher-prebuild-narrow.sh`
Expected: PASS

Run: `nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-narrow.serviceConfig.ExecStart'`
Expected: a store path ending in `/bin/vasher-prebuild narrow`

- [ ] **Step 6: Commit**

```bash
git add modules/nixos/vasher-prebuild.sh modules/nixos/vasher-prebuild.nix scripts/tests/test-vasher-prebuild-narrow.sh
git commit -m "feat(vasher): add narrow candidate mode for a chosen input set"
```

---

### Task 3: Storage fault rule

**Files:**
- Modify: `modules/nixos/vasher-prebuild-monitor.py:16-63` (constants), `:756-800` (`Controller.observe`)
- Modify: `modules/nixos/vasher-prebuild.sh:104-116` (mode dispatch, before the lock is used for work)
- Modify: `scripts/tests/test-vasher-prebuild-monitor.py`
- Test: `scripts/tests/test-vasher-prebuild-blocked.sh` (create)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `FAULT_PATH = Path("/var/lib/vasher/monitor/storage-fault.json")`, written with `atomic_json` and mode 0644. Its content is `{"revision": "<40 hex>", "pattern": "<matched pattern>", "at": "<iso8601>"}`. New status state string `blocked`.

- [ ] **Step 1: Write the failing monitor tests**

In `scripts/tests/test-vasher-prebuild-monitor.py`, add a test class covering:

```python
STORAGE_PATTERNS == ("Input/output error", "I/O error", "csum failed",
                     "failed to read block", "blk_update_request")
```

- A failed build whose log tail contains each pattern writes `FAULT_PATH` and records an event with `severity == "critical"` and `reason == "storage-fault"`.
- A failed build with no pattern writes no fault file and keeps the existing behavior.
- A fault never triggers a retry, even when every retry precondition holds.
- A btrfs `error_stats` file whose counters increased since the previous sample writes the fault file. An absent `error_stats` path is not an error.

- [ ] **Step 2: Run the monitor tests to confirm the new ones fail**

Run: `python3 scripts/tests/test-vasher-prebuild-monitor.py`
Expected: FAIL with `AttributeError` on `STORAGE_PATTERNS`

- [ ] **Step 3: Implement the rule in `modules/nixos/vasher-prebuild-monitor.py`**

Add `STORAGE_PATTERNS` and `FAULT_PATH` beside the other constants. Add `scan_storage_fault(text: str) -> str | None` that returns the first matching pattern or `None`, matched case-sensitively as a substring. Add `read_btrfs_errors(root: Path = Path("/sys/fs/btrfs")) -> int` that sums every integer in every `devinfo/*/error_stats` file it can read and returns 0 when the path is absent.

In the failure branch of `Controller.observe`, call the scan on the bounded log text. On a match, write the fault file, record the event with severity `critical` and reason `storage-fault`, set the durable state to `needs-attention`, and skip the retry path. Compare the btrfs sum against the value stored in `MonitorState`; an increase triggers the same handling with the pattern string `btrfs-error-stats`.

- [ ] **Step 4: Write the failing blocked-mode test** `scripts/tests/test-vasher-prebuild-blocked.sh`

Assert that with the fault file present, `vasher-prebuild refresh`, `candidate`, and `narrow` each write `status.json` with state `blocked`, call neither `git fetch` nor `nix build`, and exit 0.

- [ ] **Step 5: Implement the block in `modules/nixos/vasher-prebuild.sh`**

After the lock is acquired and before the repository work begins, exit with state `blocked` and code 0 when `/var/lib/vasher/monitor/storage-fault.json` exists. The script never removes that file.

- [ ] **Step 6: Run both test files**

Run: `python3 scripts/tests/test-vasher-prebuild-monitor.py && bash scripts/tests/test-vasher-prebuild-blocked.sh`
Expected: both PASS

- [ ] **Step 7: Commit**

```bash
git add modules/nixos/vasher-prebuild-monitor.py modules/nixos/vasher-prebuild.sh scripts/tests/test-vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-blocked.sh
git commit -m "feat(vasher): halt the pipeline on storage faults"
```

---

### Task 4: Action channel

**Files:**
- Create: `modules/nixos/vasher-agent-verb.py`
- Modify: `modules/nixos/vasher-prebuild.nix:88-112` (options), `:114-228` (config: users, polkit, tmpfiles)
- Test: `scripts/tests/test-vasher-agent-verb.py` (create), `scripts/tests/test-vasher-agent-closure.sh` (create)

**Interfaces:**
- Consumes: the narrow request path and unit from Task 2, the fault path from Task 3.
- Produces: `vasher-agent-verb` reading one JSON object from standard input. New option `ryk.vasherPrebuild.agentKeys` of type `listOf str`, default `[ ]`. New system user and group `vasher-agent`.

- [ ] **Step 1: Write the failing test** `scripts/tests/test-vasher-agent-verb.py`

Load the module with the `importlib` pattern. Drive `handle(request: dict, ctx: Context) -> Response` with a fake context so no test touches systemd. Cover:

```python
accepted:  retry-exact with state "needs-attention", matching revision, zero prior agent retries
accepted:  narrow-inputs with base == status baseRevision and 1..8 known inputs
accepted:  hold-input with a 29-day expiry, release-input for a held input
rejected:  every verb while the fault file exists                      -> reason "storage-fault"
rejected:  every build verb while the lock is held                     -> reason "busy"
rejected:  retry-exact with state "success"                            -> reason "state"
rejected:  retry-exact with a revision that is not the recorded one    -> reason "revision"
rejected:  retry-exact a second time for the same revision             -> reason "retry-budget"
rejected:  narrow-inputs with a stale base                             -> reason "base"
rejected:  narrow-inputs with 0 or 9 inputs, or an unknown input name   -> reason "inputs"
rejected:  hold-input with a 31-day expiry or a non-hex revision       -> reason "hold"
rejected:  the ninth accepted verb inside 24 hours                     -> reason "budget"
malformed: unknown verb, non-object JSON, >4 KiB input                 -> exit code 2
```

Also assert that an accepted `narrow-inputs` writes the request file before it starts the unit, that the rolling budget survives reloading `verbs.json` from disk, and that every accepted and rejected request appends one event with `source == "agent"`.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `python3 scripts/tests/test-vasher-agent-verb.py`
Expected: FAIL, the module does not exist

- [ ] **Step 3: Implement `modules/nixos/vasher-agent-verb.py`**

Read at most 4096 bytes from standard input and parse one JSON object. Build the command list for each action from fixed string literals. The only two unit names the program may start are `vasher-prebuild-retry.service` and `vasher-prebuild-narrow.service`, both through `systemctl start`. Reuse the `atomic_json` approach from the monitor for `holds.json`, `narrow-request.json`, and `verbs.json`. `retry-exact` writes `/var/lib/vasher/monitor/retry.json` in the shape the existing retry wrapper reads (`vasher-prebuild.nix:50-58`): `{"baseRevision": ..., "revision": ...}`. Print one JSON object with `accepted`, `reason`, and `eventId`. Exit 0 accepted, 1 rejected, 2 malformed. The program ignores `SSH_ORIGINAL_COMMAND` and never calls a shell.

- [ ] **Step 4: Wire the module in `modules/nixos/vasher-prebuild.nix`**

Build the program with `pkgs.writers.writePython3Bin`, matching the `monitor` derivation at `:46-48`. Add the `agentKeys` option. Add `users.groups.vasher-agent` and `users.users.vasher-agent` as a system user with home `/var/lib/vasher-agent`, shell `pkgs.bashInteractive`, and no supplementary groups. Add its `openssh.authorizedKeys.keys` built from `agentKeys` with the prefix `command="${agent}/bin/vasher-agent-verb",restrict `. Add a `security.polkit.extraConfig` rule that allows only user `vasher-agent`, only action `org.freedesktop.systemd1.manage-units`, and only the two unit names. Add the tmpfiles rule `d /var/lib/vasher/agent 0755 vasher-agent vasher-agent -`.

- [ ] **Step 5: Write the closure check** `scripts/tests/test-vasher-agent-closure.sh`

Model it on `scripts/tests/test-vasher-monitor-closure.sh`. Assert that `vasher-agent` is not in the `vasher` group, that the authorized key entries all begin with the forced command and `restrict`, and that the polkit rule text names exactly the two allowed units.

- [ ] **Step 6: Run both tests**

Run: `python3 scripts/tests/test-vasher-agent-verb.py && bash scripts/tests/test-vasher-agent-closure.sh`
Expected: both PASS

- [ ] **Step 7: Commit**

```bash
git add modules/nixos/vasher-agent-verb.py modules/nixos/vasher-prebuild.nix scripts/tests/test-vasher-agent-verb.py scripts/tests/test-vasher-agent-closure.sh
git commit -m "feat(vasher): add the typed agent action channel"
```

---

### Task 5: Dashboard surfaces

**Files:**
- Modify: `modules/nixos/vasher-dashboard/src/main.tsx:7` and the status description function at `:79-83`
- Modify: `modules/nixos/vasher-prebuild.nix:229-258` (Caddy virtual host)
- Modify: `modules/nixos/vasher-prebuild-monitor.py` (`_event`, to stamp `source`)

**Interfaces:**
- Consumes: the `blocked` state from Task 3 and the agent events from Task 4.
- Produces: `/api/holds.json`; `source` on every ledger event.

- [ ] **Step 1: Add the `source` field to monitor events**

Every event the monitor writes gains `"source": "monitor"`. Add one assertion to `scripts/tests/test-vasher-prebuild-monitor.py` that each written event carries a `source` value of `monitor`.

- [ ] **Step 2: Serve the hold file**

Add a `handle /api/holds.json` block to the Caddy configuration, matching the existing four blocks, with `root * /var/lib/vasher/agent`.

- [ ] **Step 3: Extend the frontend**

Add `"blocked"` to the `State` union. Add its description line: the build is stopped because the storage reported errors, and an operator clears `/var/lib/vasher/monitor/storage-fault.json` after replacing the disk. Show the event `source` beside each ledger entry. Add a holds panel that polls `/api/holds.json` on the same five-second interval, tolerates a 404 as "no holds", and marks a hold whose `expires` date has passed as expired.

- [ ] **Step 4: Verify**

Run: `python3 scripts/tests/test-vasher-prebuild-monitor.py`
Expected: PASS

Run: `nix build --no-link '.#nixosConfigurations.vasher.config.systemd.units."vasher-prebuild-monitor.service".unit'`
Expected: success, which proves the dashboard package still builds through the module

- [ ] **Step 5: Commit**

```bash
git add modules/nixos/vasher-dashboard/src/main.tsx modules/nixos/vasher-prebuild.nix modules/nixos/vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-monitor.py
git commit -m "feat(vasher): show holds, blocked state, and event source"
```

---

### Task 6: Supervisor on Jezrien

**Files:**
- Create: `modules/ai/vasher-supervisor.nix`, `modules/ai/vasher-supervise.sh`, `modules/ai/skills/vasher-supervisor/SKILL.md`
- Modify: `modules/ai/_skills.nix:10-38` (`commonSkills`), `modules/hosts/jezrien/default.nix:133` (home-manager module list)
- Test: `scripts/tests/test-vasher-supervise.sh` (create)

**Interfaces:**
- Consumes: the verb schema from Task 4 and the `blocked` state from Task 3.
- Produces: home-manager module `flake.modules.homeManager.vasher-supervisor` with option `ryk.vasherSupervisor.enable`, the `vasher-supervise` command, and the user timers `vasher-supervise` and `vasher-supervise-digest`.

- [ ] **Step 1: Write the failing test** `scripts/tests/test-vasher-supervise.sh`

Stub `curl`, `hermes`, and `notify-send` on `PATH`, with a temporary state directory supplied through an environment variable. Assert:

```
state "success", no new event ids   -> hermes is never called, exit 0
state "idle",   no new event ids    -> hermes is never called, exit 0
state "success", a new event id     -> hermes is called once
state "failed"                      -> hermes is called once
state "blocked"                     -> hermes is called once, notify-send is called
curl fails once                     -> no notification, unreachable count is 1
curl fails twice in a row           -> notify-send is called once
curl recovers                       -> unreachable count returns to 0
--digest                            -> hermes is called even when nothing changed
hermes exits non-zero               -> wrapper exits 0 and writes digest.md
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `bash scripts/tests/test-vasher-supervise.sh`
Expected: FAIL, the script does not exist

- [ ] **Step 3: Implement `modules/ai/vasher-supervise.sh`**

Fetch `http://vasher.local.ryk.sh:5080/api/status.json` and `/api/events.json` with a 10-second timeout each. Keep state in `${VASHER_SUPERVISE_STATE:-$HOME/.local/state/vasher-supervise}`: `last-seen.json` holds `lastEventId` and `unreachable`; `digest.md` holds the newest summary. Work exists when the state is one of `failed`, `stale`, `needs-attention`, `blocked`, or when an event identifier is newer than `lastEventId`. With `--digest`, work always exists. When work exists, run `hermes` once with the evidence bundle on standard input and the skill name in the prompt, write `digest.md` from its output, and call `notify-send` when the state is `failed`, `needs-attention`, or `blocked`. The wrapper always exits 0 unless its own arguments are wrong.

The evidence bundle is the status record, the newest three events, and a log tail of at most 200 lines and 32 KiB fetched from `/api/log.txt`, with authorization headers, tokens, and credential query parameters removed.

- [ ] **Step 4: Write the skill** `modules/ai/skills/vasher-supervisor/SKILL.md`

Front matter `name: vasher-supervisor` and a description naming Vasher incident triage. The body states the four verbs with their exact JSON shapes and preconditions from the spec, the channel command `ssh -i ~/.ssh/vasher-agent vasher-agent@vasher.local.ryk.sh`, and the rule that the agent proposes a verb and Vasher decides. It states that a rejection is a normal answer and must not be retried with a different shape.

- [ ] **Step 5: Implement `modules/ai/vasher-supervisor.nix`**

Expose `flake.modules.homeManager.vasher-supervisor` with `ryk.vasherSupervisor.enable`. Package the wrapper with `pkgs.writeShellApplication`, runtime inputs `curl`, `jq`, `coreutils`, and `libnotify`. Define `systemd.user.services.vasher-supervise` plus `systemd.user.timers.vasher-supervise` with `OnCalendar = "*:0/30"` and `Persistent = true`, and a second service and timer pair with `--digest` on `OnCalendar = "Mon *-*-* 09:00:00"`.

- [ ] **Step 6: Register the skill and the module**

Add `{ name = "vasher-supervisor"; src = ./skills/vasher-supervisor; }` to `commonSkills` in `modules/ai/_skills.nix`. Add `vasher-supervisor` to the home-manager module list in `modules/hosts/jezrien/default.nix` beside `hermes-agent`, and set `ryk.vasherSupervisor.enable = true` for Jezrien.

- [ ] **Step 7: Verify**

Run: `bash scripts/tests/test-vasher-supervise.sh`
Expected: PASS

Run: `nix eval --json '.#nixosConfigurations.jezrien.config.home-manager.users.dusty.systemd.user.timers.vasher-supervise.Timer'`
Expected: an object containing `OnCalendar` with the value `*:0/30`

- [ ] **Step 8: Commit**

```bash
git add modules/ai/vasher-supervisor.nix modules/ai/vasher-supervise.sh modules/ai/skills/vasher-supervisor modules/ai/_skills.nix modules/hosts/jezrien/default.nix scripts/tests/test-vasher-supervise.sh
git commit -m "feat(ai): supervise Vasher from Hermes on a schedule"
```

---

### Task 7: Whole-flake check and documentation

**Files:**
- Modify: `wiki/entities/vasher.md`, `wiki/index.md`, `wiki/log.md`

**Interfaces:**
- Consumes: every earlier task.
- Produces: nothing for later tasks.

- [ ] **Step 1: Evaluate the whole flake**

Run: `nix flake check`
Expected: success. Fix any evaluation error this plan introduced before continuing.

- [ ] **Step 2: Run every Vasher test**

Run:

```bash
for t in scripts/tests/test-vasher*.sh; do echo "== $t"; bash "$t" || exit 1; done
for t in scripts/tests/test-vasher*.py; do echo "== $t"; python3 "$t" || exit 1; done
```

Expected: every file passes.

- [ ] **Step 3: Update the wiki**

In `wiki/entities/vasher.md`, add the hold list, the narrow mode, the action channel with its four verbs and the security boundary, the storage-fault state and the operator command that clears it, and the Hermes supervisor with its trigger and its read-only observation path. Keep the existing section order and voice. Add the new source files to the front-matter `sources` list.

Add the supervisor skill and module to `wiki/index.md` where the AI modules are listed. Append one dated entry to `wiki/log.md` naming the branch and the design document.

- [ ] **Step 4: Commit**

```bash
git add wiki/
git commit -m "docs(vasher): document the agent channel and storage-fault halt"
```
