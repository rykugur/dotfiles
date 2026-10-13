import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { formatTimestamp } from "./date-format.ts";
import { eventSource, mergeEvents, type MonitorEvent, renderEventText } from "./event-text.ts";
import { HoldsPanel, type HoldMap } from "./holds.ts";
import "./dashboard.css";

type State =
  | "idle"
  | "preparing"
  | "building"
  | "success"
  | "failed"
  | "stale"
  | "blocked";
type Mode = "refresh" | "candidate" | "retry";

type Status = {
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

type Snapshot = {
  status: Status | null;
  history: Status[];
  log: string;
  events: MonitorEvent[];
  holds: HoldMap;
  error: string | null;
};

const emptySnapshot: Snapshot = {
  status: null,
  history: [],
  log: "",
  events: [],
  holds: {},
  error: null,
};

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(path, { cache: "no-store" });
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json() as Promise<T>;
}

async function fetchJsonOr<T>(path: string, fallback: T): Promise<T> {
  const response = await fetch(path, { cache: "no-store" });
  if (response.status === 404) return fallback;
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json() as Promise<T>;
}

async function loadSnapshot(): Promise<Snapshot> {
  const [status, history, log, monitorEvents, agentEvents, holds] = await Promise.all([
    fetchJson<Status>("/api/status.json"),
    fetchJson<Status[]>("/api/history.json"),
    fetch("/api/log.txt", { cache: "no-store" }).then(async (response) => {
      if (!response.ok) throw new Error(`/api/log.txt: ${response.status}`);
      return response.text();
    }),
    fetchJsonOr<MonitorEvent[]>("/api/events.json", []),
    fetchJsonOr<MonitorEvent[]>("/api/agent-events.json", []),
    fetchJsonOr<HoldMap>("/api/holds.json", {}),
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

function useSnapshot(): Snapshot {
  const [snapshot, setSnapshot] = useState(emptySnapshot);

  useEffect(() => {
    let cancelled = false;
    const refresh = () => {
      loadSnapshot()
        .then((next) => !cancelled && setSnapshot(next))
        .catch((error: unknown) => {
          if (!cancelled) setSnapshot((current) => ({ ...current, error: String(error) }));
        });
    };
    refresh();
    const interval = window.setInterval(refresh, 5_000);
    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, []);

  return snapshot;
}

function shortRevision(revision: string): string {
  return revision ? `${revision.slice(0, 12)}${revision.length > 12 ? "…" : ""}` : "pending";
}

function statusCopy(status: Status): string {
  if (status.state === "preparing") return "Updating candidate inputs before the build.";
  if (status.state === "stale") return "Candidate discarded because master advanced.";
  if (status.state === "building") return "Refreshing package inputs and warming Jezrien’s reduced closure.";
  if (status.state === "success") return "Published to cache-bump and retained as a cache root.";
  if (status.state === "failed") return `Build stopped with exit code ${status.exitCode ?? "unknown"}.`;
  if (status.state === "blocked")
    return "Builds are stopped because the storage reported errors. An operator clears /var/lib/vasher/monitor/storage-fault.json after replacing the disk.";
  return "Current cache-bump already covers master.";
}

function App() {
  const { status, history, log, events, holds, error } = useSnapshot();

  return (
    <main>
      <header>
        <div>
          <p className="eyebrow">LAN build cache / CT 200</p>
          <h1>vasher / work ledger</h1>
        </div>
        <p className={`pulse ${error ? "failed" : status?.state ?? "idle"}`}>
          <span aria-hidden="true" className="dot" />
          {error ? "status unavailable; retrying in 5 seconds" : "auto refresh every 5 seconds"}
        </p>
      </header>

      {!status ? (
        <section className="panel empty"><h2>Current candidate</h2><p>Awaiting Vasher status.</p></section>
      ) : (
        <section className="layout">
          <article className="panel"><h2>Current candidate</h2><div className="hero">
            <p className={`state ${status.state}`}>{status.state.toUpperCase()}</p>
            <p className="sub">{statusCopy(status)}</p>
            <dl>
              <dt>Base revision</dt><dd>{shortRevision(status.baseRevision)}</dd>
              <dt>Candidate</dt><dd>{shortRevision(status.revision)}</dd>
              <dt>Mode</dt><dd>{status.mode}</dd>
              <dt>Excluded</dt><dd>{status.excludedPackages.join(", ") || "none"}</dd>
              <dt>Updated</dt><dd>{formatTimestamp(status.updatedAt)}</dd>
            </dl>
          </div></article>
          <aside className="panel"><h2>Scheduler</h2><div className="scheduler">
            <div><p className="eyebrow">Refresh probe</p><p className="clock">15m</p><p className="sub">after the previous run</p></div>
            <div><p className="eyebrow">Nightly candidate</p><p className="clock">03:00</p><p className="sub">randomized delay ≤ 10m</p></div>
          </div></aside>
          <HoldsPanel holds={holds} />
          <article className="panel full">
            <h2>Events</h2>
            <ol className="events">
              {events.length === 0 ? (
                <li>No events recorded yet.</li>
              ) : events.map((event) => {
                const text = renderEventText(event);
                return (
                  <li key={event.id} className={`event ${event.severity}`}>
                    <time>{formatTimestamp(event.timestamp)}</time>
                    <div>
                      <p className="event-title">
                        {text.title}
                        <span className="event-source">{eventSource(event)}</span>
                      </p>
                      <p className="event-detail">{text.detail}</p>
                      {text.summary ? <p className="event-summary">{text.summary}</p> : null}
                      {event.inferenceError ? <p className="event-error">Inference error: {event.inferenceError}</p> : null}
                    </div>
                  </li>
                );
              })}
            </ol>
          </article>
          <article className="panel full"><h2>Recent runs</h2><ol className="runs">
            {history.length === 0 ? <li>No terminal builds recorded yet.</li> : history.map((run) => <li key={`${run.updatedAt}-${run.state}`}><time>{formatTimestamp(run.updatedAt)}</time><span className={`badge ${run.state}`}>{run.state.toUpperCase()}</span><span>{shortRevision(run.revision || run.baseRevision)}</span></li>)}
          </ol></article>
          <article className="panel full"><h2>Latest build log</h2><pre>{log || "No captured build output yet."}</pre></article>
        </section>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
