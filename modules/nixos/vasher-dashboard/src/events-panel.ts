import { createElement, type ReactNode } from "react";
import { formatTimestamp } from "./date-format.ts";
import { eventSource, renderEventText, type MonitorEvent } from "./event-text.ts";

type EventsPanelProps = {
  events: MonitorEvent[];
  agentEventsDegraded: boolean;
};

export function EventsPanel({ events, agentEventsDegraded }: EventsPanelProps) {
  const items: ReactNode[] = events.map((event) => {
    const text = renderEventText(event);
    return createElement(
      "li",
      { key: event.id, className: `event ${event.severity}` },
      createElement("time", null, formatTimestamp(event.timestamp)),
      createElement(
        "div",
        null,
        createElement(
          "p",
          { className: "event-title" },
          text.title,
          createElement("span", { className: "event-source" }, eventSource(event)),
        ),
        createElement("p", { className: "event-detail" }, text.detail),
        text.summary
          ? createElement("p", { className: "event-summary" }, text.summary)
          : null,
        event.inferenceError
          ? createElement(
              "p",
              { className: "event-error" },
              `Inference error: ${event.inferenceError}`,
            )
          : null,
      ),
    );
  });
  if (agentEventsDegraded) {
    items.unshift(createElement("li", { key: "agent-events-degraded" }, "Agent event log unavailable."));
  } else if (items.length === 0) {
    items.push(createElement("li", { key: "events-empty" }, "No events recorded yet."));
  }
  return createElement(
    "article",
    { className: "panel full" },
    createElement("h2", null, "Events"),
    createElement("ol", { className: "events" }, items),
  );
}
