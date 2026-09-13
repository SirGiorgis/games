"use client";

import { StopCopyingButton } from "@/components/StopCopyingButton";
import { currentDrawdownPct } from "@/engine/risk";
import { useSimulation } from "@/hooks/useSimulation";
import { eur, pct } from "@/lib/format";
import { useSimulatorStore } from "@/store/simulatorStore";

export default function RiskPage() {
  const result = useSimulation();
  const settings = useSimulatorStore((s) => s.settings);
  const stopCopying = useSimulatorStore((s) => s.stopCopying);
  const m = result.metrics;
  const peak = result.equityCurve.reduce((p, pt) => Math.max(p, pt.equity), settings.startingBalance);
  const dd = currentDrawdownPct(m.endingEquity, peak);

  const checks = [
    {
      label: "STOP COPYING",
      ok: !stopCopying,
      value: stopCopying ? "Active — no new paper trades" : "Off",
    },
    {
      label: "Simultaneous positions",
      ok: m.openPositionCount < settings.maxSimultaneousPositions,
      value: `${m.openPositionCount} / ${settings.maxSimultaneousPositions}`,
    },
    {
      label: "Max position size",
      ok: true,
      value: eur(settings.maxPositionSize),
    },
    {
      label: "Daily loss limit",
      ok: true,
      value: eur(settings.maxDailyLoss),
    },
    {
      label: "Drawdown limit",
      ok: dd < settings.maxTotalDrawdownPct,
      value: `${pct(dd)} used of ${pct(settings.maxTotalDrawdownPct)}`,
    },
    {
      label: "Available cash",
      ok: m.availableCash > 0.01,
      value: eur(m.availableCash),
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-black">Risk management</h1>
          <p className="mt-1 max-w-3xl text-sm" style={{ color: "var(--muted)" }}>
            Hard limits on the virtual follower. A rejected copy is recorded; it is never sent to a
            broker. Real order execution does not exist in this application.
          </p>
        </div>
        <StopCopyingButton />
      </div>

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        {checks.map((c) => (
          <article key={c.label} className="card flex items-start justify-between gap-3 p-4">
            <div>
              <div className="text-sm font-bold">{c.label}</div>
              <div className="tabular mt-1 text-lg">{c.value}</div>
            </div>
            <span
              className="rounded-full px-2 py-1 text-xs font-black uppercase"
              style={{
                background: c.ok ? "#14532d33" : "var(--banner-bg)",
                color: c.ok ? "var(--profit)" : "var(--banner-fg)",
              }}
            >
              {c.ok ? "Clear" : "Blocked"}
            </span>
          </article>
        ))}
      </div>

      <section className="card space-y-2 p-4 text-sm" style={{ color: "var(--muted)" }}>
        <h2 className="font-bold" style={{ color: "var(--text)" }}>
          Automatic reject / reduce rules
        </h2>
        <ul className="list-disc space-y-1 pl-5">
          <li>Reduce size if copy percentage would exceed max position size or remaining cash.</li>
          <li>Reject if the daily realized loss limit has been reached.</li>
          <li>Reject if peak-to-trough drawdown has reached the configured maximum.</li>
          <li>Reject if the simultaneous position cap has been reached.</li>
          <li>Reject if virtual cash cannot fund fees plus notional.</li>
          <li>Reject every new entry while STOP COPYING is active.</li>
        </ul>
      </section>
    </div>
  );
}
