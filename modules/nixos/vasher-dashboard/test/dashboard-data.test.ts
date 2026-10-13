import assert from "node:assert/strict";
import test from "node:test";
import { loadSnapshot, type DashboardFetch } from "../src/dashboard-data.ts";

const status = {
  state: "blocked" as const,
  mode: "candidate" as const,
  startedAt: "2026-10-12T09:00:00Z",
  updatedAt: "2026-10-12T10:00:00Z",
  baseRevision: "1".repeat(40),
  revision: "2".repeat(40),
  output: "",
  excludedPackages: [],
};

const monitorEvent = {
  id: "monitor-event",
  timestamp: "2026-10-12T10:00:00Z",
  revision: "2".repeat(40),
  type: "needs-attention",
  severity: "error" as const,
  reason: "storage-fault",
  metrics: {},
  action: "stop-final",
  source: "monitor" as const,
};

const agentEvent = {
  id: "agent-event",
  timestamp: "2026-10-12T11:00:00Z",
  revision: "2".repeat(40),
  type: "agent-verb",
  severity: "info" as const,
  reason: "accepted",
  metrics: null,
  action: "hold-input",
  source: "agent" as const,
};

const validHolds = {
  nixpkgs: {
    revision: "3".repeat(40),
    expires: "2026-10-13",
    reason: "upstream regression",
  },
};

function json(value: unknown): Response {
  return new Response(JSON.stringify(value), {
    headers: { "content-type": "application/json" },
  });
}

type EndpointResult = Response | Error;

function endpoint(result: EndpointResult): () => Response {
  return () => {
    if (result instanceof Error) throw result;
    return result.clone();
  };
}

function fetchWith(agentEvents: EndpointResult, holds: EndpointResult): DashboardFetch {
  const responses: Record<string, () => Response> = {
    "/api/status.json": () => json(status),
    "/api/history.json": () => json([]),
    "/api/log.txt": () => new Response("trusted log"),
    "/api/events.json": () => json([monitorEvent]),
    "/api/agent-events.json": endpoint(agentEvents),
    "/api/holds.json": endpoint(holds),
  };
  return async (path) => {
    const response = responses[path];
    if (!response) throw new Error(`unexpected path: ${path}`);
    return response();
  };
}

for (const [name, brokenAgentEvents] of [
  ["transport failure", new Error("connection reset")],
  ["malformed JSON", new Response("{broken")],
  ["server error", new Response("failed", { status: 503 })],
  ["wrong top-level type", json({ event: agentEvent })],
] as const) {
  test(`trusted snapshot survives agent events ${name}`, async () => {
    const snapshot = await loadSnapshot(fetchWith(brokenAgentEvents, json(validHolds)));

    assert.equal(snapshot.status.state, "blocked");
    assert.equal(snapshot.log, "trusted log");
    assert.deepEqual(snapshot.events.map(({ id }) => id), ["monitor-event"]);
    assert.deepEqual(snapshot.holds, validHolds);
    assert.equal(snapshot.agentEventsDegraded, true);
    assert.equal(snapshot.holdsDegraded, false);
  });
}

for (const [name, brokenHolds] of [
  ["transport failure", new Error("connection reset")],
  ["malformed JSON", new Response("{broken")],
  ["server error", new Response("failed", { status: 503 })],
  ["wrong top-level type", json([validHolds.nixpkgs])],
] as const) {
  test(`trusted snapshot survives holds ${name}`, async () => {
    const snapshot = await loadSnapshot(fetchWith(json([agentEvent]), brokenHolds));

    assert.equal(snapshot.status.state, "blocked");
    assert.equal(snapshot.log, "trusted log");
    assert.deepEqual(snapshot.events.map(({ id }) => id), ["agent-event", "monitor-event"]);
    assert.deepEqual(snapshot.holds, {});
    assert.equal(snapshot.agentEventsDegraded, false);
    assert.equal(snapshot.holdsDegraded, true);
  });
}

test("optional endpoint 404 is empty without degradation", async () => {
  const missing = new Response("", { status: 404 });
  const snapshot = await loadSnapshot(fetchWith(missing, missing));
  assert.deepEqual(snapshot.events.map(({ id }) => id), ["monitor-event"]);
  assert.deepEqual(snapshot.holds, {});
  assert.equal(snapshot.agentEventsDegraded, false);
  assert.equal(snapshot.holdsDegraded, false);
});

test("optional endpoint degradation clears on the next snapshot", async () => {
  const degraded = await loadSnapshot(
    fetchWith(new Response("{broken"), new Response("failed", { status: 500 })),
  );
  const recovered = await loadSnapshot(fetchWith(json([agentEvent]), json(validHolds)));
  assert.equal(degraded.agentEventsDegraded, true);
  assert.equal(degraded.holdsDegraded, true);
  assert.equal(recovered.agentEventsDegraded, false);
  assert.equal(recovered.holdsDegraded, false);
});
