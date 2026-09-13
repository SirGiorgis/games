"use client";

import {
  BalanceChart,
  ChartCard,
  DrawdownChart,
  EquityChart,
  TradePnlChart,
} from "@/components/Charts";
import { MetricCard } from "@/components/MetricCard";
import { OpenPositions } from "@/components/OpenPositions";
import { StopCopyingButton } from "@/components/StopCopyingButton";
import { STRATEGY_META } from "@/engine/defaults";
import { useSimulation } from "@/hooks/useSimulation";
import { eur, num, pct } from "@/lib/format";
import { useSimulatorStore } from "@/store/simulatorStore";

export default function DashboardPage() {
  const result = useSimulation();
  const m = result.metrics;
  const strategyId = useSimulatorStore((s) => s.strategyId);
  const stopCopying = useSimulatorStore((s) => s.stopCopying);
  const pnlTone = m.totalPnl > 0 ? "profit" : m.totalPnl < 0 ? "loss" : "neutral";

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-black">Dashboard</h1>
          <p className="mt-1 max-w-2xl text-sm" style={{ color: "var(--muted)" }}>
            Simulated copy of the <strong>{STRATEGY_META[strategyId].title}</strong> leader on local
            sample data. Virtual € account only — no live market access and no real orders.
          </p>
        </div>
        <StopCopyingButton />
      </div>

      {stopCopying ? (
        <div className="card p-3 text-sm font-semibold" style={{ background: "var(--banner-bg)", color: "var(--banner-fg)" }}>
          STOP COPYING is on. The engine still replays history, but the follower opens no new paper trades.
        </div>
      ) : null}

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <MetricCard label="Virtual balance" value={eur(m.endingEquity)} hint="Marked paper equity" />
        <MetricCard label="Total profit/loss" value={eur(m.totalPnl)} tone={pnlTone} />
        <MetricCard label="Return" value={pct(m.returnPct)} tone={pnlTone} />
        <MetricCard label="Available cash" value={eur(m.availableCash)} />
        <MetricCard label="Open positions" value={String(m.openPositionCount)} />
        <MetricCard label="Number of trades" value={String(m.tradeCount)} />
        <MetricCard label="Winning trades" value={String(m.winningTrades)} tone="profit" />
        <MetricCard label="Losing trades" value={String(m.losingTrades)} tone="loss" />
        <MetricCard label="Win rate" value={pct(m.winRatePct)} />
        <MetricCard label="Average winning trade" value={eur(m.averageWin)} />
        <MetricCard label="Average losing trade" value={eur(m.averageLoss)} />
        <MetricCard label="Maximum drawdown" value={pct(m.maxDrawdownPct)} hint={eur(m.maxDrawdownEur)} />
        <MetricCard label="Largest loss" value={eur(m.largestLoss)} tone="loss" />
        <MetricCard label="Largest win" value={eur(m.largestWin)} tone="profit" />
        <MetricCard label="Current exposure" value={eur(m.currentExposure)} />
        <MetricCard label="Profit factor" value={num(m.profitFactor)} />
      </section>

      <section className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        <ChartCard title="Account cash over time">
          <BalanceChart points={result.equityCurve} />
        </ChartCard>
        <ChartCard title="Equity curve">
          <EquityChart points={result.equityCurve} />
        </ChartCard>
        <ChartCard title="Drawdown">
          <DrawdownChart points={result.equityCurve} />
        </ChartCard>
        <ChartCard title="Individual trade results">
          <TradePnlChart trades={result.closedTrades} />
        </ChartCard>
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-bold">Open paper positions</h2>
        <OpenPositions positions={result.openPositions} />
      </section>
    </div>
  );
}
