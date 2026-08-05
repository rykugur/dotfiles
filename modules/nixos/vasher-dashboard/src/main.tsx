import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "./dashboard.css";

type State = "idle" | "building" | "success" | "failed" | "stale";
type Mode = "refresh" | "candidate";

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
  error: string | null;
};

const emptySnapshot: Snapshot = { status: null, history: [], log: "", error: null };

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(path, { cache: "no-store" });
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json() as Promise<T>;
}

async function loadSnapshot(): Promise<Snapshot> {
  const [status, history, log] = await Promise.all([
    fetchJson<Status>("/api/status.json"),
    fetchJson<Status[]>("/api/history.json"),
    fetch("/api/log.txt", { cache: "no-store" }).then(async (response) => {
      if (!response.ok) throw new Error(`/api/log.txt: ${response.status}`);
      return response.text();
    }),
  ]);
  return { status, history, log, error: null };
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
  if (status.state === "stale") return "Candidate discarded because master advanced.";
  if (status.state === "building") return "Refreshing package inputs and warming Jezrien’s reduced closure.";
  if (status.state === "success") return "Published to cache-bump and retained as a cache root.";
  if (status.state === "failed") return `Build stopped with exit code ${status.exitCode ?? "unknown"}.`;
  return "Current cache-bump already covers master.";
}

function App() {
  const { status, history, log, error } = useSnapshot();

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
              <dt>Updated</dt><dd>{new Date(status.updatedAt).toLocaleString()}</dd>
            </dl>
          </div></article>
          <aside className="panel"><h2>Scheduler</h2><div className="scheduler">
            <div><p className="eyebrow">Refresh probe</p><p className="clock">15m</p><p className="sub">after the previous run</p></div>
            <div><p className="eyebrow">Nightly candidate</p><p className="clock">03:00</p><p className="sub">randomized delay ≤ 10m</p></div>
          </div></aside>
          <article className="panel full"><h2>Recent runs</h2><ol className="runs">
            {history.length === 0 ? <li>No terminal builds recorded yet.</li> : history.map((run) => <li key={`${run.updatedAt}-${run.state}`}><time>{new Date(run.updatedAt).toLocaleString()}</time><span className={`badge ${run.state}`}>{run.state.toUpperCase()}</span><span>{shortRevision(run.revision || run.baseRevision)}</span></li>)}
          </ol></article>
          <article className="panel full"><h2>Latest build log</h2><pre>{log || "No captured build output yet."}</pre></article>
        </section>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
