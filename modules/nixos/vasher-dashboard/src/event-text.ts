export type MonitorEvent = {
  id: string;
  timestamp: string;
  revision: string;
  type: string;
  severity: "info" | "warning" | "error";
  reason: string | null;
  metrics: Record<string, number | string>;
  action: string | null;
  summary?: string;
  inferenceError?: string;
};

export type EventText = {
  title: string;
  detail: string;
  summary: string | null;
};

export function renderEventText(event: MonitorEvent): EventText {
  return {
    title: event.type.replaceAll("-", " ").toUpperCase(),
    detail: [event.reason, event.action].filter(Boolean).join(" / ") || "observation",
    summary: event.summary ?? null,
  };
}
