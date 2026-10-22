import assert from "node:assert/strict";
import test from "node:test";
import { formatDuration, getLedgerState, loadRunLog, startSnapshotPolling } from "../src/live-ledger.ts";
import type { LiveSample, Status } from "../src/dashboard-data.ts";

const status: Status = {
  state: "building",
  mode: "candidate",
  startedAt: "2026-10-22T12:00:00Z",
  updatedAt: "2026-10-22T12:00:05Z",
  baseRevision: "a".repeat(40),
  revision: "b".repeat(40),
  output: "",
  excludedPackages: [],
};
const live: LiveSample = {
  sampledAt: "2026-10-22T12:00:00Z",
  activeUnit: "vasher-prebuild.service",
  mode: "candidate",
  statusState: "building",
  memAvailable: 12_000,
  swapFree: 13_000,
  diskFree: 14_000,
  nixMemory: 15_000,
  memoryPressureFull: 0.4,
};
const now = Date.parse("2026-10-22T12:00:00Z");

test("running requires an active unit, fresh heartbeat, and matching in-progress status", () => {
  assert.equal(getLedgerState(status, live, now), "running");
  assert.equal(getLedgerState(status, { ...live, activeUnit: null }, now), "unknown");
  assert.equal(getLedgerState(status, { ...live, sampledAt: "2026-10-22T11:58:30Z" }, now), "unknown");
  assert.equal(getLedgerState(status, { ...live, sampledAt: "bad" }, now), "unknown");
  assert.equal(getLedgerState(status, { ...live, statusState: "success" }, now), "unknown");
  assert.equal(getLedgerState({ ...status, state: "success" }, live, now), "unknown");
  assert.equal(getLedgerState(status, null, now), "unknown");
  assert.equal(getLedgerState(null, { ...live, activeUnit: null }, now), "unknown");
});

test("the 90-second heartbeat boundary is stale", () => {
  assert.equal(getLedgerState(status, live, now + 89_999), "running");
  assert.equal(getLedgerState(status, live, now + 90_000), "unknown");
});

test("an inactive heartbeat after failure is idle, while missing heartbeat remains unknown", () => {
  assert.equal(getLedgerState({ ...status, state: "failed" }, { ...live, activeUnit: null }, now), "idle");
  assert.equal(getLedgerState({ ...status, state: "failed" }, null, now), "unknown");
  assert.equal(getLedgerState({ ...status, state: "blocked" }, null, now), "unknown");
  assert.equal(getLedgerState({ ...status, state: "blocked" }, { ...live, activeUnit: null }, now), "blocked");
  assert.equal(getLedgerState({ ...status, state: "success" }, { ...live, activeUnit: null }, now), "idle");
});

test("elapsed time never claims a duration from invalid or inverted timestamps", () => {
  assert.equal(formatDuration("2026-10-22T12:00:00Z", "2026-10-22T13:05:02Z"), "1h 5m");
  assert.equal(formatDuration("2026-10-22T12:00:00Z", "2026-10-22T12:00:42Z"), "42s");
  assert.equal(formatDuration("invalid", "2026-10-22T12:00:42Z"), "—");
  assert.equal(formatDuration("2026-10-22T12:00:42Z", "2026-10-22T12:00:00Z"), "—");
});

test("an archived log is fetched only on request and with no-store", async () => {
  const calls: string[] = [];
  const run = { ...status, id: "20261022-120000_ab", logPath: "/api/runs/20261022-120000_ab.txt" };
  const fetcher = async (path: string, init: { cache: "no-store" }) => {
    calls.push(`${path}:${init.cache}`);
    return new Response("redacted archived log");
  };
  assert.equal(calls.length, 0);
  assert.equal(await loadRunLog(run, fetcher), "redacted archived log");
  assert.deepEqual(calls, ["/api/runs/20261022-120000_ab.txt:no-store"]);
  assert.equal(await loadRunLog(status, fetcher), null);
  assert.equal(calls.length, 1);
});

test("run log paths cannot redirect archive requests", async () => {
  const run = { ...status, id: "trusted", logPath: "/api/runs/../status.json" };
  await assert.rejects(loadRunLog(run, async () => { throw new Error("must not fetch"); }), /Invalid archived log path/);
});

test("polling starts immediately, ticks every 5 seconds, discards late replies and stops after disposal", async () => {
  let tick: (() => void) | undefined;
  let delay = 0;
  let cancelled = false;
  const pending: Array<(value: string) => void> = [];
  const delivered: string[] = [];
  const stop = startSnapshotPolling(
    () => new Promise<string>((resolve) => { pending.push(resolve); }),
    (value) => delivered.push(value),
    () => { throw new Error("unexpected load failure"); },
    () => {},
    (refresh, milliseconds) => {
      tick = refresh;
      delay = milliseconds;
      return () => { cancelled = true; };
    },
  );
  assert.equal(delay, 5_000);
  assert.equal(pending.length, 1);
  tick?.();
  pending[1]("latest");
  await Promise.resolve();
  pending[0]("old");
  await Promise.resolve();
  assert.deepEqual(delivered, ["latest"]);
  stop();
  assert.equal(cancelled, true);
  tick?.();
  assert.equal(pending.length, 2);
});
