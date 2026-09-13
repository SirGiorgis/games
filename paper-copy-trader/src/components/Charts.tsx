"use client";

import { eur } from "@/lib/format";
import type { ClosedTrade, EquityPoint } from "@/engine/types";
import {
  Area,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ComposedChart,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

function stamp(ts: number): string {
  return new Date(ts).toISOString().slice(0, 10);
}

function tooltipStyle(): React.CSSProperties {
  return {
    background: "var(--bg-elev)",
    border: "1px solid var(--line)",
    borderRadius: 12,
    color: "var(--text)",
    fontSize: 12,
  };
}

export function BalanceChart({ points }: { points: EquityPoint[] }) {
  const data = points.filter((_, i) => i % 4 === 0 || i === points.length - 1).map((p) => ({
    t: stamp(p.timestamp),
    cash: Number(p.cash.toFixed(2)),
    equity: Number(p.equity.toFixed(2)),
  }));
  return (
    <ResponsiveContainer width="100%" height={240}>
      <LineChart data={data}>
        <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
        <XAxis dataKey="t" hide />
        <YAxis tick={{ fontSize: 11 }} width={64} />
        <Tooltip formatter={(v) => eur(Number(v))} contentStyle={tooltipStyle()} />
        <Line type="monotone" dataKey="cash" stroke="var(--blue)" dot={false} strokeWidth={2} name="Cash" />
      </LineChart>
    </ResponsiveContainer>
  );
}

export function EquityChart({ points }: { points: EquityPoint[] }) {
  const data = points.filter((_, i) => i % 4 === 0 || i === points.length - 1).map((p) => ({
    t: stamp(p.timestamp),
    equity: Number(p.equity.toFixed(2)),
  }));
  return (
    <ResponsiveContainer width="100%" height={240}>
      <ComposedChart data={data}>
        <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
        <XAxis dataKey="t" hide />
        <YAxis tick={{ fontSize: 11 }} width={64} />
        <Tooltip formatter={(v) => eur(Number(v))} contentStyle={tooltipStyle()} />
        <Area type="monotone" dataKey="equity" stroke="var(--accent)" fill="var(--accent-soft)" name="Equity" />
      </ComposedChart>
    </ResponsiveContainer>
  );
}

export function DrawdownChart({ points }: { points: EquityPoint[] }) {
  const data = points.filter((_, i) => i % 4 === 0 || i === points.length - 1).map((p) => ({
    t: stamp(p.timestamp),
    dd: Number((-p.drawdownPct).toFixed(2)),
  }));
  return (
    <ResponsiveContainer width="100%" height={240}>
      <AreaChartShim data={data} />
    </ResponsiveContainer>
  );
}

function AreaChartShim({ data }: { data: { t: string; dd: number }[] }) {
  return (
    <ComposedChart data={data}>
      <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
      <XAxis dataKey="t" hide />
      <YAxis tick={{ fontSize: 11 }} width={48} />
      <Tooltip formatter={(v) => `${Number(v).toFixed(2)}%`} contentStyle={tooltipStyle()} />
      <Area type="monotone" dataKey="dd" stroke="var(--loss)" fill="#dc262633" name="Drawdown" />
    </ComposedChart>
  );
}

export function TradePnlChart({ trades }: { trades: ClosedTrade[] }) {
  const data = trades.map((t, i) => ({
    i: i + 1,
    pnl: t.netPnl,
  }));
  if (data.length === 0) {
    return <EmptyChart text="No closed paper trades yet." />;
  }
  return (
    <ResponsiveContainer width="100%" height={240}>
      <BarChart data={data}>
        <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
        <XAxis dataKey="i" tick={{ fontSize: 11 }} />
        <YAxis tick={{ fontSize: 11 }} width={56} />
        <Tooltip formatter={(v) => eur(Number(v))} contentStyle={tooltipStyle()} />
        <Bar dataKey="pnl" name="Net P/L">
          {data.map((d, idx) => (
            <Cell key={idx} fill={d.pnl >= 0 ? "var(--profit)" : "var(--loss)"} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}

export function EmptyChart({ text }: { text: string }) {
  return (
    <div className="flex h-[240px] items-center justify-center text-sm" style={{ color: "var(--muted)" }}>
      {text}
    </div>
  );
}

export function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="card p-3 sm:p-4">
      <h2 className="mb-3 text-sm font-bold">{title}</h2>
      <div className="h-[240px] w-full">{children}</div>
    </section>
  );
}
