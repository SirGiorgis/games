"use client";

import { eur, num, pnlClass, sideLabel, when } from "@/lib/format";
import type { OpenPosition } from "@/engine/types";

export function OpenPositions({ positions }: { positions: OpenPosition[] }) {
  if (positions.length === 0) {
    return (
      <div className="card p-4 text-sm" style={{ color: "var(--muted)" }}>
        No open paper positions.
      </div>
    );
  }
  return (
    <div className="card overflow-x-auto">
      <table className="min-w-[720px] w-full text-sm">
        <thead style={{ color: "var(--muted)" }}>
          <tr className="border-b" style={{ borderColor: "var(--line)" }}>
            <th className="px-3 py-2 text-left">Asset</th>
            <th className="px-3 py-2 text-left">Direction</th>
            <th className="px-3 py-2 text-left">Qty</th>
            <th className="px-3 py-2 text-left">Entry</th>
            <th className="px-3 py-2 text-left">Stop</th>
            <th className="px-3 py-2 text-left">Target</th>
            <th className="px-3 py-2 text-left">Notional</th>
            <th className="px-3 py-2 text-left">Opened</th>
          </tr>
        </thead>
        <tbody>
          {positions.map((p) => (
            <tr key={p.id} className="border-b" style={{ borderColor: "var(--line)" }}>
              <td className="px-3 py-2 font-semibold">{p.asset}</td>
              <td className="px-3 py-2">{sideLabel(p.side)}</td>
              <td className="tabular px-3 py-2">{num(p.quantity, 6)}</td>
              <td className="tabular px-3 py-2">{num(p.entryPrice, 4)}</td>
              <td className={`tabular px-3 py-2 ${pnlClass(-1)}`}>{num(p.stopLoss, 4)}</td>
              <td className={`tabular px-3 py-2 ${pnlClass(1)}`}>{num(p.takeProfit, 4)}</td>
              <td className="tabular px-3 py-2">{eur(p.notional)}</td>
              <td className="px-3 py-2">{when(p.entryTime)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
