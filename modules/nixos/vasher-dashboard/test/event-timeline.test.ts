import assert from "node:assert/strict";
import test from "node:test";
import { eventSource, mergeEvents, renderEventText, type MonitorEvent } from "../src/event-text.ts";

test("event text preserves model content as text", () => {
  const value = renderEventText({
    id: "event-1",
    timestamp: "2026-09-02T22:00:00Z",
    revision: "2".repeat(40),
    type: "needs-attention",
    severity: "error",
    reason: "memory",
    metrics: {},
    action: "stop-final",
    summary: "<script>globalThis.pwned = true</script>",
  });
  assert.equal(value.summary, "<script>globalThis.pwned = true</script>");
});

function event(id: string, timestamp: string): MonitorEvent {
  return {
    id,
    timestamp,
    revision: "2".repeat(40),
    type: "build-observed",
    severity: "info",
    reason: null,
    metrics: {},
    action: null,
  };
}

test("event ledgers merge newest-first without deduplicating timestamps", () => {
  const merged = mergeEvents(
    [event("monitor-old", "2026-10-12T09:00:00Z"), event("monitor-new", "2026-10-12T11:00:00Z")],
    [event("agent-same-time", "2026-10-12T11:00:00Z"), event("agent-middle", "2026-10-12T10:00:00Z")],
  );

  assert.deepEqual(
    merged.map(({ id }) => id),
    ["monitor-new", "agent-same-time", "agent-middle", "monitor-old"],
  );
});

test("merged event ledger is capped at 100 entries", () => {
  const events = Array.from({ length: 101 }, (_, index) =>
    event(`event-${index}`, new Date(Date.UTC(2026, 9, 12, 0, index)).toISOString()),
  );

  const merged = mergeEvents(events, []);

  assert.equal(merged.length, 100);
  assert.equal(merged[0]?.id, "event-100");
  assert.equal(merged.at(-1)?.id, "event-1");
});

test("events without a source retain the monitor compatibility default", () => {
  assert.equal(eventSource(event("legacy", "2026-10-12T09:00:00Z")), "monitor");
  assert.equal(
    eventSource({ ...event("agent", "2026-10-12T09:00:00Z"), source: "agent" }),
    "agent",
  );
});
