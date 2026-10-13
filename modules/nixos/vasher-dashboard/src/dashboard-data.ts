import { mergeEvents, type MonitorEvent } from "./event-text.ts";
import type { HoldMap } from "./holds.ts";

export type State =
  | "idle"
  | "preparing"
  | "building"
  | "success"
  | "failed"
  | "stale"
  | "blocked";
export type Mode = "refresh" | "candidate" | "retry";

export type Status = {
  state: State;
  mode: Mode;
  startedAt: string;
  updatedAt: string;
  baseRevision: string;
  revision: string;
  output: string;
  excludedPackages: string[];
  exitCode?: number;
};

export type Snapshot = {
  status: Status;
  history: Status[];
  log: string;
  events: MonitorEvent[];
  holds: HoldMap;
  error: null;
};

export type DashboardFetch = (
  path: string,
  init: { cache: "no-store" },
) => Promise<Response>;

async function fetchJson<T>(fetcher: DashboardFetch, path: string): Promise<T> {
  const response = await fetcher(path, { cache: "no-store" });
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json() as Promise<T>;
}

async function fetchJsonOr<T>(
  fetcher: DashboardFetch,
  path: string,
  fallback: T,
): Promise<T> {
  const response = await fetcher(path, { cache: "no-store" });
  if (response.status === 404) return fallback;
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json() as Promise<T>;
}
function isAgentEventArray(value: unknown): value is MonitorEvent[] {
  return Array.isArray(value);
}

function isHoldMap(value: unknown): value is HoldMap {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

async function fetchOptionalAgentJson<T>(
  fetcher: DashboardFetch,
  path: string,
  fallback: T,
  validate: (value: unknown) => value is T,
): Promise<T> {
  try {
    const response = await fetcher(path, { cache: "no-store" });
    if (!response.ok) return fallback;
    const value: unknown = await response.json();
    return validate(value) ? value : fallback;
  } catch {
    return fallback;
  }
}


export async function loadSnapshot(
  fetcher: DashboardFetch = fetch,
): Promise<Snapshot> {
  const [status, history, log, monitorEvents, agentEvents, holds] = await Promise.all([
    fetchJson<Status>(fetcher, "/api/status.json"),
    fetchJson<Status[]>(fetcher, "/api/history.json"),
    fetcher("/api/log.txt", { cache: "no-store" }).then(async (response) => {
      if (!response.ok) throw new Error(`/api/log.txt: ${response.status}`);
      return response.text();
    }),
    fetchJsonOr<MonitorEvent[]>(fetcher, "/api/events.json", []),
    fetchOptionalAgentJson(
      fetcher,
      "/api/agent-events.json",
      [],
      isAgentEventArray,
    ),
    fetchOptionalAgentJson(fetcher, "/api/holds.json", {}, isHoldMap),
  ]);
  return {
    status,
    history,
    log,
    events: mergeEvents(monitorEvents, agentEvents),
    holds,
    error: null,
  };
}
