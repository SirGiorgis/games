"use client";

import { ChartCard, EquityChart } from "@/components/Charts";
import { CsvLoader } from "@/components/CsvLoader";
import { MetricCard } from "@/components/MetricCard";
import { SettingsForm } from "@/components/SettingsForm";
import { STRATEGY_META } from "@/engine/defaults";
import { useSimulation } from "@/hooks/useSimulation";
import { eur, num, pct } from "@/lib/format";
import { useSimulatorStore } from "@/store/simulatorStore";

export default function BacktestPage() {
  const result = useSimulation();
  const strategyId = useSimulatorStore((s) => s.strategyId);
  const m = result.metrics;

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-black">Backtest</h1>
        <p className="mt-1 max-w-3xl text-sm" style={{ color: "var(--muted)" }}>
          Replay of local sample bars for the selected leader. Signals are computed on the close of
          each bar and filled on the next open, so the rules cannot use future prices. This is not a
          live market backtest and results can differ from any real history.
        </p>
      </div>

      <div className="card p-4 text-sm" style={{ color: "var(--muted)" }}>
        Leader: <strong style={{ color: "var(--text)" }}>{STRATEGY_META[strategyId].title}</strong>{" "}
        · Sample data only · {STRATEGY_META[strategyId].disclaimer}
      </div>

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <MetricCard label="Starting balance" value={eur(m.startingBalance)} />
        <MetricCard label="Ending balance" value={eur(m.endingEquity)} />
        <MetricCard label="Total return" value={pct(m.returnPct)} />
        <MetricCard label="Maximum drawdown" value={pct(m.maxDrawdownPct)} />
        <MetricCard label="Number of trades" value={String(m.tradeCount)} />
        <MetricCard label="Win rate" value={pct(m.winRatePct)} />
        <MetricCard label="Profit factor" value={num(m.profitFactor)} />
        <MetricCard label="Sharpe ratio" value={num(m.sharpeRatio)} hint="Needs enough daily equity points" />
      </section>

      <ChartCard title="Backtest equity curve">
        <EquityChart points={result.equityCurve} />
      </ChartCard>

      <CsvLoader />

      <section className="space-y-2">
        <h2 className="text-sm font-bold">Backtest inputs</h2>
        <SettingsForm />
      </section>
    </div>
  );
}
