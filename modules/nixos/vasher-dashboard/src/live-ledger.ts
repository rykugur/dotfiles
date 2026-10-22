import type { DashboardFetch, LiveSample, Status } from "./dashboard-data.ts";

export type LedgerState = "running" | "unknown" | "idle" | "blocked";

export function getLedgerState(status: Status | null, live: LiveSample | null, now: number): LedgerState {
  if (!status) return "unknown";
  const sampledAt = live ? Date.parse(live.sampledAt) : NaN;
  if (!Number.isFinite(sampledAt) || Math.abs(now - sampledAt) >= 90_000) return "unknown";
  if (live?.activeUnit) {
    return (status.state === "building" || status.state === "preparing")
      && live.statusState === status.state ? "running" : "unknown";
  }
  if (status.state === "building" || status.state === "preparing") return "unknown";
  if (status.state === "blocked") return "blocked";
  return "idle";
}

export function formatDuration(start: string, end: string | number): string {
  const elapsed = (typeof end === "number" ? end : Date.parse(end)) - Date.parse(start);
  if (!Number.isFinite(elapsed) || elapsed < 0) return "—";
  const seconds = Math.floor(elapsed / 1000);
  if (seconds >= 3600) return `${Math.floor(seconds / 3600)}h ${Math.floor((seconds % 3600) / 60)}m`;
  if (seconds >= 60) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
  return `${seconds}s`;
}

export async function loadRunLog(run: Status, fetcher: DashboardFetch = fetch): Promise<string | null> {
  if (!run.logPath) return null;
  if (!run.id || !/^[A-Za-z0-9_-]+$/.test(run.id)
    || run.logPath !== `/api/runs/${run.id}.txt`) throw new Error("Invalid archived log path");
  const response = await fetcher(run.logPath, { cache: "no-store" });
  if (!response.ok) throw new Error(`Archived log unavailable (${response.status})`);
  return response.text();
}

export function startSnapshotPolling<T>(
  load: () => Promise<T>,
  onSnapshot: (snapshot: T) => void,
  onError: (error: unknown) => void,
  onTick: () => void,
  schedule: (refresh: () => void, milliseconds: number) => () => void = (refresh, milliseconds) => {
    const interval = setInterval(refresh, milliseconds);
    return () => clearInterval(interval);
  },
): () => void {
  let stopped = false;
  let request = 0;
  const refresh = () => {
    if (stopped) return;
    const current = ++request;
    onTick();
    load()
      .then((snapshot) => {
        if (!stopped && current === request) onSnapshot(snapshot);
      })
      .catch((error: unknown) => {
        if (!stopped && current === request) onError(error);
      });
  };
  refresh();
  const unschedule = schedule(refresh, 5_000);
  return () => {
    stopped = true;
    unschedule();
  };
}
