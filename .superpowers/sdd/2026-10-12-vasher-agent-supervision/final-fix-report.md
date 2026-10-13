# Final fix report

Status: COMPLETE

Implementation commit: `21d6a5ce` (`fix(vasher): close final supervision review`)

## Changes

- Monitor sampling, stopping, and fail-safe recovery now cover `vasher-prebuild-narrow.service`.
- Unattended Hermes runs with `--toolsets todo --ignore-rules`; the prompt remains one argument and the 300-second internal timeout remains unchanged.
- Rejection lockout probes log to syslog without mutating `verbs.json` or `events.json` and return a null event ID.
- Both supervisor services allow seven minutes; unreachable notification delivery retries until `notify-send` succeeds.
- Generic `I/O error` matching was removed; failed-build btrfs sampling wording now matches implementation.
- Dashboard snapshots preserve trusted data while independently reporting unavailable agent events and holds; 404 remains a non-degraded empty result.
- SSH action transport is batch-only, has a ten-second connect timeout, and requires strict host-key checking.
- Design and wiki documentation now covers deployment host-key seeding, the real hold/release smoke test, module/skill ownership, all-held behavior, and the constrained model boundary.

## TDD evidence

- `nix shell nixpkgs#python3 -c python3 scripts/tests/test-vasher-prebuild-monitor.py` — RED: 4 expected failures (narrow unit not sampled/stopped, generic `I/O error` still matched, old pattern tuple); GREEN: 64 tests, OK.
- `nix shell nixpkgs#python3 -c python3 scripts/tests/test-vasher-agent-verb.py` — RED: lockout returned a non-null event ID; GREEN: 78 tests, OK.
- `bash scripts/tests/test-vasher-supervise.sh` — RED: Hermes CLI shape missing required flags; GREEN: `PASS: vasher-supervise behavior`.
- `npm test` — RED: degradation flags absent and events panel missing; after implementation and dependency installation: 21 tests, 21 pass.

## Verification

- `for test in scripts/tests/test-vasher*.sh scripts/tests/test-vasher*.py; do case "$test" in *.sh) bash "$test" ;; *.py) nix shell nixpkgs#python3 -c python3 "$test" ;; esac || exit; done` — exit 0; all Vasher shell tests passed, agent suite 78 tests OK, monitor suite 64 tests OK.
- `npm ci && npm test && npm run build` — dependencies installed; 21 tests passed; the first build found a TypeScript array-inference error in the new events panel.
- `npm test && npm run build && rm -rf node_modules dist` — 21 tests passed; TypeScript passed; Vite built 33 modules; generated artifacts removed.
- `nix flake check` — exit 0, `all checks passed!`; existing deprecation warnings only.
- `nix build --no-link '.#nixosConfigurations.vasher.config.systemd.units."vasher-prebuild-monitor.service".unit'` — exit 0.
- `nix build --no-link '.#nixosConfigurations.vasher.config.systemd.units."vasher-prebuild-narrow.service".unit'` — exit 0.
- `bash scripts/tests/test-vasher-agent-closure.sh` — included in the all-Vasher run; exit 0 and rebuilt the action closure.
- `nix build --no-link --impure --expr 'let f = builtins.getFlake (toString ./.); ps = f.nixosConfigurations.jezrien.config.home-manager.users.dusty.home.packages; in builtins.head (builtins.filter (p: (p.name or "") == "vasher-supervise") ps)'` — exit 0; supervisor package built. The unavailable Vasher binary-cache hostname produced retries before the local build.
- `nix eval --json '.#nixosConfigurations.jezrien.config.home-manager.users.dusty.systemd.user.timers.vasher-supervise.Timer'` — `{"OnCalendar":"*:0/30","Persistent":true}`.
- `nix eval --json '.#nixosConfigurations.jezrien.config.home-manager.users.dusty.systemd.user.timers.vasher-supervise-digest.Timer'` — `{"OnCalendar":"Mon *-*-* 09:00:00","Persistent":true}`.
- Both focused `TimeoutStartSec` evals — `7min`.
- `git diff --check` — exit 0.

## Concerns

- Deployment still requires the documented verified `known_hosts` entry, dedicated key provisioning, and real hold/release smoke test. No NixOS or Home Manager activation was performed.
