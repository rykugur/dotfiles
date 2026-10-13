import { createElement } from "react";

export type Hold = {
  revision: string;
  expires: string;
  reason: string;
  createdAt?: string;
};

export type HoldMap = Record<string, Hold>;

export function localToday(now = new Date()): string {
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function isHoldExpired(expires: string, today = localToday()): boolean {
  return expires < today;
}

type HoldsPanelProps = {
  holds: HoldMap;
  today?: string;
};

export function HoldsPanel({ holds, today = localToday() }: HoldsPanelProps) {
  const entries = Object.entries(holds);
  return createElement(
    "article",
    { className: "panel full" },
    createElement("h2", null, "Input holds"),
    createElement(
      "ol",
      { className: "holds" },
      entries.length === 0
        ? createElement("li", null, "No input holds recorded.")
        : entries.map(([input, hold]) => {
            const expired = isHoldExpired(hold.expires, today);
            return createElement(
              "li",
              { className: `hold ${expired ? "expired" : "active"}`, key: input },
              createElement(
                "dl",
                null,
                createElement("dt", null, "Input"),
                createElement("dd", null, input),
                createElement("dt", null, "Revision"),
                createElement("dd", null, hold.revision),
                createElement("dt", null, "Expires"),
                createElement("dd", null, hold.expires),
                createElement("dt", null, "Reason"),
                createElement("dd", null, hold.reason),
                createElement("dt", null, "State"),
                createElement(
                  "dd",
                  null,
                  createElement(
                    "span",
                    { className: `badge ${expired ? "expired" : "active"}` },
                    expired ? "EXPIRED" : "ACTIVE",
                  ),
                ),
              ),
            );
          }),
    ),
  );
}
