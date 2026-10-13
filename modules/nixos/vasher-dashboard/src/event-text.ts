export type MonitorEvent = {
  id: string;
  timestamp: string;
  revision: string | null;
  type: string;
  severity: "info" | "warning" | "error";
  reason: string | null;
  metrics: Record<string, number | string> | null;
  action: string | null;
  source?: "monitor" | "agent";
  summary?: string;
  inferenceError?: string;
  verb?: string;
  accepted?: boolean;
};

export type EventText = {
  title: string;
  detail: string;
  summary: string | null;
};

export function eventSource(event: MonitorEvent): "monitor" | "agent" {
  return event.source ?? "monitor";
}

export function mergeEvents(
  monitorEvents: MonitorEvent[],
  agentEvents: MonitorEvent[],
): MonitorEvent[] {
  const merged = [...monitorEvents, ...agentEvents];
  merged.sort((left, right) => {
    if (left.timestamp === right.timestamp) return 0;
    return left.timestamp < right.timestamp ? 1 : -1;
  });
  if (merged.length > 100) merged.length = 100;
  return merged;
}

export function renderEventText(event: MonitorEvent): EventText {
  return {
    title: event.type.replaceAll("-", " ").toUpperCase(),
    detail: [event.reason, event.action].filter(Boolean).join(" / ") || "observation",
    summary: event.summary ?? null,
  };
}
