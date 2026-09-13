"use client";

import { MetricCard } from "@/components/MetricCard";
import { compareStrategies } from "@/engine/backtest";
import { STRATEGY_META } from "@/engine/defaults";
import type { StrategyId } from "@/engine/types";
import { eur, num, pct } from "@/lib/format";
import { useSimulatorStore } from "@/store/simulatorStore";
import { useMemo } from "react";

const IDS: StrategyId[] = ["conservative", "balanced", "aggressive"];

export default function StrategiesPage() {
  const settings = useSimulatorStore((s) => s.settings);
  const strategyId = useSimulatorStore((s) => s.strategyId);
  const setStrategyId = useSimulatorStore((s) => s.setStrategyId);
  const stopCopying = useSimulatorStore((s) => s.stopCopying);

  const results = useMemo(() => compareStrategies(settings), [settings]);

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-black">Strategies</h1>
        <p className="mt-1 max-w-3xl text-sm" style={{ color: "var(--muted)" }}>
          These are hypothetical leader rules used only to generate sample trades. They are not
          financial advice. None of them is claimed to be profitable or suitable for live trading.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
        {IDS.map((id) => {
          const meta = STRATEGY_META[id];
          const m = results[id].metrics;
          const active = strategyId === id;
          return (
            <button
              key={id}
              type="button"
              onClick={() => setStrategyId(id)}
              className="card p-4 text-left"
              style={{
                outline: active ? "2px solid var(--accent)" : "2px solid transparent",
              }}
            >
              <div className="text-xs font-bold uppercase tracking-[0.16em]" style={{ color: "var(--muted)" }}>
                {active ? "Selected leader" : "Hypothetical leader"}
              </div>
              <h2 className="mt-1 text-xl font-black">{meta.title}</h2>
              <p className="mt-2 text-sm" style={{ color: "var(--muted)" }}>
                {meta.summary}
              </p>
              <p className="mt-2 text-xs" style={{ color: "var(--muted)" }}>
                {meta.disclaimer}
              </p>
              <div className="mt-4 grid grid-cols-2 gap-2 text-sm">
                <div>
                  Total return
                  <div className="tabular font-semibold">{pct(m.returnPct)}</div>
                </div>
                <div>
                  Max DD
                  <div className="tabular font-semibold">{pct(m.maxDrawdownPct)}</div>
                </div>
                <div>
                  Win rate
                  <div className="tabular font-semibold">{pct(m.winRatePct)}</div>
                </div>
                <div>
                  Trades
                  <div className="tabular font-semibold">{m.tradeCount}</div>
                </div>
              </div>
            </button>
          );
        })}
      </div>

      {stopCopying ? (
        <p className="text-sm font-semibold" style={{ color: "var(--banner-fg)" }}>
          STOP COPYING is active, so the dashboard follower will not open new copies of the selected leader.
        </p>
      ) : null}

      <div className="card overflow-x-auto">
        <table className="min-w-[860px] w-full text-sm">
          <thead style={{ color: "var(--muted)" }}>
            <tr className="border-b" style={{ borderColor: "var(--line)" }}>
              <th className="px-3 py-2 text-left">Metric</th>
              {IDS.map((id) => (
                <th key={id} className="px-3 py-2 text-left">
                  {STRATEGY_META[id].title}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {(
              [
                ["Total return", (id: StrategyId) => pct(results[id].metrics.returnPct)],
                ["Annualized return", (id: StrategyId) => pct(results[id].metrics.annualizedReturnPct)],
                ["Maximum drawdown", (id: StrategyId) => pct(results[id].metrics.maxDrawdownPct)],
                ["Win rate", (id: StrategyId) => pct(results[id].metrics.winRatePct)],
                ["Profit factor", (id: StrategyId) => num(results[id].metrics.profitFactor)],
                ["Sharpe ratio", (id: StrategyId) => num(results[id].metrics.sharpeRatio)],
                ["Number of trades", (id: StrategyId) => String(results[id].metrics.tradeCount)],
                ["Average trade", (id: StrategyId) => eur(results[id].metrics.averageTrade)],
                ["Best trade", (id: StrategyId) => eur(results[id].metrics.largestWin)],
                ["Worst trade", (id: StrategyId) => eur(results[id].metrics.largestLoss)],
              ] as const
            ).map(([label, getter]) => (
              <tr key={label} className="border-b" style={{ borderColor: "var(--line)" }}>
                <td className="px-3 py-2 font-semibold">{label}</td>
                {IDS.map((id) => (
                  <td key={id} className="tabular px-3 py-2">
                    {getter(id)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {IDS.map((id) => (
          <MetricCard
            key={id}
            label={`${STRATEGY_META[id].title} ending equity`}
            value={eur(results[id].metrics.endingEquity)}
          />
        ))}
      </div>
    </div>
  );
}
