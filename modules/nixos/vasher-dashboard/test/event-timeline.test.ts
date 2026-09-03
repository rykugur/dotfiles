import assert from "node:assert/strict";
import test from "node:test";
import { renderEventText } from "../src/event-text.ts";

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
