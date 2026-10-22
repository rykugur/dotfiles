import { StrictMode, useEffect, useState, type SyntheticEvent } from "react";
import { createRoot } from "react-dom/client";
import "@fontsource-variable/inter";
import "@fontsource-variable/jetbrains-mono";
import { formatTimestamp } from "./date-format.ts";
import { loadSnapshot, type Snapshot, type Status } from "./dashboard-data.ts";
import { EventsPanel } from "./events-panel.ts";
import { HoldsPanel } from "./holds.ts";
import { formatDuration, getLedgerState, loadRunLog, startSnapshotPolling } from "./live-ledger.ts";
import "./dashboard.css";

type DashboardState = Omit<Snapshot, "status" | "error"> & {
  status: Status | null;
  error: string | null;
};

const emptySnapshot: DashboardState = {
  status: null,
  history: [],
  live: null,
  log: "",
  events: [],
  holds: {},
  agentEventsDegraded: false,
  holdsDegraded: false,
  error: null,
};

function useSnapshot(): [DashboardState, number] {
  const [snapshot, setSnapshot] = useState(emptySnapshot);
  const [now, setNow] = useState(Date.now());

  useEffect(() => startSnapshotPolling(
    loadSnapshot,
    setSnapshot,
    (error) => setSnapshot((previous) => ({ ...previous, error: String(error) })),
    () => setNow(Date.now()),
  ), []);

  return [snapshot, now];
}

function shortRevision(revision: string): string {
  return revision ? `${revision.slice(0, 12)}${revision.length > 12 ? "…" : ""}` : "pending";
}

function statusCopy(status: Status): string {
  if (status.state === "preparing") return "Updating candidate inputs before the build.";
  if (status.state === "stale") return "Candidate discarded because master advanced.";
  if (status.state === "building") return "Building Jezrien’s reduced Nix closure.";
  if (status.state === "success") return "Published to cache-bump and retained as a cache root.";
  if (status.state === "failed") return `Build stopped with exit code ${status.exitCode ?? "unknown"}.`;
  if (status.state === "blocked")
    return "Builds are stopped because storage reported errors. An operator must clear the storage fault after replacing the disk.";
  return "Current cache-bump already covers master.";
}

function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes < 0) return "—";
  const unit = bytes >= 1024 ** 3 ? "GiB" : "MiB";
  const divisor = unit === "GiB" ? 1024 ** 3 : 1024 ** 2;
  return `${(bytes / divisor).toFixed(1)} ${unit}`;
}

function RunRow({ run }: { run: Status }) {
  const [text, setText] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [requested, setRequested] = useState(false);
  const retained = Boolean(run.logPath);

  function onToggle(event: SyntheticEvent<HTMLDetailsElement>) {
    if (!event.currentTarget.open || !retained || requested) return;
    setRequested(true);
    setLoading(true);
    loadRunLog(run)
      .then((content) => setText(content))
      .catch(() => setError(true))
      .finally(() => setLoading(false));
  }

  return (
    <li className="run">
      <details onToggle={onToggle}>
        <summary>
          <time dateTime={run.updatedAt}>{formatTimestamp(run.updatedAt)}</time>
          <span className={`badge ${run.state}`}>{run.state}</span>
          <span className="run-revision" title={run.revision || run.baseRevision}>{shortRevision(run.revision || run.baseRevision)}</span>
          <span className="run-duration">{formatDuration(run.startedAt, run.updatedAt)}</span>
        </summary>
        <div className="run-detail">
          <dl>
            <dt>Mode</dt><dd>{run.mode}</dd>
            <dt>Revision</dt><dd>{run.revision || run.baseRevision || "pending"}</dd>
            <dt>Duration</dt><dd>{formatDuration(run.startedAt, run.updatedAt)}</dd>
            <dt>Exit code</dt><dd>{run.exitCode ?? "not recorded"}</dd>
          </dl>
          {!retained ? <p>Log not retained for this run.</p>
            : loading ? <p>Loading archived log…</p>
            : error ? <p>Archived log unavailable. Reload the page to try again.</p>
            : <pre aria-label="Archived run log">{text || "No captured output for this run."}</pre>}
        </div>
      </details>
    </li>
  );
}

function App() {
  const [{ status, history, live, log, events, holds, agentEventsDegraded, holdsDegraded, error }, now] = useSnapshot();
  const ledgerState = getLedgerState(status, live, now);
  const running = ledgerState === "running";
  const lastSample = live ? Date.parse(live.sampledAt) : NaN;
  const freshSample = Number.isFinite(lastSample) && Math.abs(now - lastSample) < 90_000;
  const headline = running ? "Build in progress"
    : ledgerState === "blocked" ? "Builds blocked" : ledgerState === "idle" ? "No active build" : "Build activity unknown";
  const terminalRuns = history.filter((run) => run.state !== "preparing" && run.state !== "building").slice(0, 20);

  return (
    <main>
      <header>
        <div>
          <p className="site-label">Vasher · build cache</p>
          <h1>Work ledger</h1>
          <p className="header-sub">Live build activity and retained run history</p>
        </div>
        <p className={`connection ${error ? "connection-error" : ""}`}>
          <span aria-hidden="true" className="connection-dot" />
          {error ? "Status unavailable · retrying" : "Refreshes every 5 seconds"}
        </p>
      </header>

      <section className={`panel activity ${ledgerState}`} aria-labelledby="activity-title">
        <div className="activity-head">
          <div>
            <p className="section-label">Current activity</p>
            <h2 id="activity-title">{headline}</h2>
          </div>
          <span role="status" className={`activity-indicator ${ledgerState}`} aria-label={`Activity: ${ledgerState}`}>
            <span aria-hidden="true" className="activity-light" />
            {running ? "Live" : ledgerState}
          </span>
        </div>
        <p className="activity-description">
          {running && status ? statusCopy(status)
            : ledgerState === "unknown" ? freshSample
              ? "A fresh sample has no matching in-progress status. Waiting for the next update."
              : "No fresh build heartbeat. The last status is not proof that a build is running."
            : status ? statusCopy(status) : "Awaiting Vasher status."}
        </p>
        {ledgerState === "unknown" && Number.isFinite(lastSample) && live &&
          <p className="last-sample">Last heartbeat <time dateTime={live.sampledAt}>{formatTimestamp(live.sampledAt)}</time></p>}
        {status && (
          <dl className="activity-facts">
            {running && <><dt>Phase</dt><dd>{status.state === "preparing" ? "Preparing candidate" : "Building closure"}</dd></>}
            {running && <><dt>Elapsed</dt><dd>{formatDuration(status.startedAt, now)}</dd></>}
            {!running && <><dt>{status.state === "preparing" || status.state === "building" ? "Recorded state" : "Last result"}</dt><dd><span className={`badge ${status.state}`}>{status.state}</span>
              {status.state === "failed" && ` · Exit code ${status.exitCode ?? "unknown"}`}</dd></>}
            <dt>Mode</dt><dd>{running ? live?.mode : status.mode}</dd>
            <dt>Candidate</dt><dd title={status.revision}>{shortRevision(status.revision)}</dd>
            <dt>Base revision</dt><dd title={status.baseRevision}>{shortRevision(status.baseRevision)}</dd>
            <dt>Excluded packages</dt><dd>{status.excludedPackages.join(", ") || "none"}</dd>
            <dt>Last status update</dt><dd><time dateTime={status.updatedAt}>{formatTimestamp(status.updatedAt)}</time></dd>
          </dl>
        )}
        {running && live && (
          <div role="group" className="resources" aria-label="Live resource sample">
            <div><span>Memory available</span><strong>{formatBytes(live.memAvailable)}</strong></div>
            <div><span>Swap free</span><strong>{formatBytes(live.swapFree)}</strong></div>
            <div><span>Disk free</span><strong>{formatBytes(live.diskFree)}</strong></div>
            <div><span>Nix memory</span><strong>{formatBytes(live.nixMemory)}</strong></div>
            <div><span>Memory pressure · full avg10</span><strong>{live.memoryPressureFull.toFixed(2)}%</strong></div>
            <p>Sampled <time dateTime={live.sampledAt}>{formatTimestamp(live.sampledAt)}</time></p>
          </div>
        )}
      </section>

      <div className="ledger-grid">
        <article className="panel latest-log">
          <div className="panel-heading"><h2>Latest build log</h2><span>Recent captured output</span></div>
          <pre aria-label="Latest build log">{log || "No captured build output yet."}</pre>
        </article>
        <article className="panel history">
          <div className="panel-heading"><h2>Recent runs</h2><span>Last 20 terminal runs</span></div>
          <ol className="runs">
            {terminalRuns.length === 0 ? <li className="list-empty">No completed runs recorded yet.</li>
              : terminalRuns.map((run, index) =>
                <RunRow key={run.id ?? `${run.updatedAt}-${run.state}-${index}`} run={run} />)}
          </ol>
        </article>
        <HoldsPanel holds={holds} degraded={holdsDegraded} />
        <EventsPanel events={events} agentEventsDegraded={agentEventsDegraded} />
      </div>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
