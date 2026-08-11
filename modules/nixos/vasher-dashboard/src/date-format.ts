const timestampFormatter = new Intl.DateTimeFormat("en-US", {
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

export function formatTimestamp(timestamp: string): string {
  return timestampFormatter
    .formatToParts(new Date(timestamp))
    .map(({ type, value }) => (type === "year" ? value.padStart(4, "0") : value))
    .join("");
}
