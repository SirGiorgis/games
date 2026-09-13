export function eur(value: number | null | undefined, digits = 2): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "—";
  return new Intl.NumberFormat("en-IE", {
    style: "currency",
    currency: "EUR",
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(value);
}

export function pct(value: number | null | undefined, digits = 2): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "—";
  return `${value.toFixed(digits)}%`;
}

export function num(value: number | null | undefined, digits = 2): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "—";
  if (!Number.isFinite(value)) return "∞";
  return value.toFixed(digits);
}

export function when(ts: number | null | undefined): string {
  if (!ts) return "—";
  return new Date(ts).toISOString().replace("T", " ").slice(0, 16) + " UTC";
}

export function pnlClass(value: number | null | undefined): string {
  if (value === null || value === undefined || value === 0) return "text-[var(--muted)]";
  return value > 0 ? "text-profit" : "text-loss";
}

export function sideLabel(side: "buy" | "sell"): string {
  return side === "buy" ? "Buy / Long" : "Sell / Short";
}
