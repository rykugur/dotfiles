import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { EventsPanel } from "../src/events-panel.ts";

test("degraded agent events render unavailable instead of an empty claim", () => {
  const markup = renderToStaticMarkup(
    createElement(EventsPanel, { events: [], agentEventsDegraded: true }),
  );
  assert.match(markup, /Agent event log unavailable\./);
  assert.doesNotMatch(markup, /No events recorded yet\./);
});

test("event text remains escaped while the endpoint is degraded", () => {
  const markup = renderToStaticMarkup(
    createElement(EventsPanel, {
      agentEventsDegraded: true,
      events: [{
        id: "malicious",
        timestamp: "2026-10-12T00:00:00Z",
        revision: "2".repeat(40),
        type: "agent-verb",
        severity: "warning",
        reason: "<img src=x onerror=alert(1)>",
        metrics: null,
        action: "hold-input",
        source: "agent",
      }],
    }),
  );
  assert.match(markup, /&lt;img src=x onerror=alert\(1\)&gt;/);
  assert.doesNotMatch(markup, /<img\b/);
});
