import assert from "node:assert/strict";
import test from "node:test";
import { formatTimestamp } from "../src/date-format.ts";

test("formats timestamps in US date order with a 24-hour clock", () => {
  assert.equal(formatTimestamp("2026-08-10T22:48:48Z"), "08/10/2026, 22:48:48");
  assert.equal(formatTimestamp("0001-01-01T00:00:00Z"), "01/01/0001, 00:00:00");
});
