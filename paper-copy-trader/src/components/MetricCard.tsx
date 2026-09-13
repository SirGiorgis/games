import { pnlClass } from "@/lib/format";

export function MetricCard({
  label,
  value,
  hint,
  tone = "neutral",
  numeric = true,
}: {
  label: string;
  value: string;
  hint?: string;
  tone?: "neutral" | "profit" | "loss";
  numeric?: boolean;
}) {
  const color =
    tone === "profit" ? "text-profit" : tone === "loss" ? "text-loss" : pnlClass(undefined);
  return (
    <article className="card p-3 sm:p-4">
      <div className="text-[11px] font-semibold uppercase tracking-[0.14em]" style={{ color: "var(--muted)" }}>
        {label}
      </div>
      <div className={`${numeric ? "tabular" : ""} mt-1 text-lg font-semibold sm:text-xl ${tone === "neutral" ? "" : color}`}>
        {value}
      </div>
      {hint ? (
        <div className="mt-1 text-xs" style={{ color: "var(--muted)" }}>
          {hint}
        </div>
      ) : null}
    </article>
  );
}
