"use client";

import { TradeTable } from "@/components/TradeTable";
import { useSimulation } from "@/hooks/useSimulation";

export default function TradesPage() {
  const result = useSimulation();
  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-black">Trades</h1>
        <p className="mt-1 max-w-3xl text-sm" style={{ color: "var(--muted)" }}>
          Closed follower paper trades only. Fees, slippage, gross P/L and net P/L are simulated.
          Rejected copy attempts are listed below the log.
        </p>
      </div>
      <TradeTable trades={result.closedTrades} />
      <section className="card overflow-x-auto p-0">
        <div className="px-4 py-3 text-sm font-bold">Rejected copy attempts</div>
        <table className="min-w-[720px] w-full text-sm">
          <thead style={{ color: "var(--muted)" }}>
            <tr className="border-y" style={{ borderColor: "var(--line)" }}>
              <th className="px-3 py-2 text-left">Time</th>
              <th className="px-3 py-2 text-left">Asset</th>
              <th className="px-3 py-2 text-left">Side</th>
              <th className="px-3 py-2 text-left">Reason</th>
              <th className="px-3 py-2 text-left">Detail</th>
            </tr>
          </thead>
          <tbody>
            {result.rejectedTrades.slice(0, 80).map((r, i) => (
              <tr key={`${r.timestamp}-${r.asset}-${i}`} className="border-b" style={{ borderColor: "var(--line)" }}>
                <td className="px-3 py-2">{new Date(r.timestamp).toISOString().slice(0, 16)}</td>
                <td className="px-3 py-2">{r.asset}</td>
                <td className="px-3 py-2">{r.side}</td>
                <td className="px-3 py-2">{r.reason}</td>
                <td className="px-3 py-2 text-xs" style={{ color: "var(--muted)" }}>
                  {r.detail}
                </td>
              </tr>
            ))}
            {result.rejectedTrades.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center" style={{ color: "var(--muted)" }}>
                  No copy attempts were rejected in this run.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </section>
    </div>
  );
}
