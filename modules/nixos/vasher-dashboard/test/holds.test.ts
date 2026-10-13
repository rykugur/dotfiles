import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { HoldsPanel, isHoldExpired, localToday } from "../src/holds.ts";

test("hold expiry compares against the local calendar date", () => {
  assert.equal(isHoldExpired("2026-10-11", "2026-10-12"), true);
  assert.equal(isHoldExpired("2026-10-12", "2026-10-12"), false);
  assert.equal(isHoldExpired("2026-10-13", "2026-10-12"), false);
});

test("local date uses the browser timezone instead of UTC", () => {
  const previousTimezone = process.env.TZ;
  process.env.TZ = "America/Los_Angeles";
  try {
    assert.equal(localToday(new Date("2026-10-12T00:30:00Z")), "2026-10-11");
  } finally {
    if (previousTimezone === undefined) delete process.env.TZ;
    else process.env.TZ = previousTimezone;
  }
});

test("client-controlled hold reason renders as text, not an image", () => {
  const reason = "<img src=x onerror=alert(1)>";
  const markup = renderToStaticMarkup(
    createElement(HoldsPanel, {
      holds: {
        nixpkgs: {
          revision: "2".repeat(40),
          expires: "2026-10-13",
          reason,
        },
      },
      today: "2026-10-12",
    }),
  );

  assert.match(markup, /&lt;img src=x onerror=alert\(1\)&gt;/);
  assert.doesNotMatch(markup, /<img\b/);
});
