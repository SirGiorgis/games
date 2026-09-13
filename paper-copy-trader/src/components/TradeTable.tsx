"use client";

import { sideLabel, eur, num, pnlClass, when } from "@/lib/format";
import type { ClosedTrade } from "@/engine/types";
import { useMemo, useState } from "react";

type SortKey = keyof Pick<
  ClosedTrade,
  "exitTime" | "asset" | "side" | "entry" | "exit" | "positionSize" | "fees" | "slippage" | "grossPnl" | "netPnl" | "balanceAfter"
>;

export function TradeTable({ trades }: { trades: ClosedTrade[] }) {
  const [query, setQuery] = useState("");
  const [side, setSide] = useState<"all" | "buy" | "sell">("all");
  const [asset, setAsset] = useState("all");
  const [sortKey, setSortKey] = useState<SortKey>("exitTime");
  const [asc, setAsc] = useState(false);

  const assets = useMemo(() => [...new Set(trades.map((t) => t.asset))], [trades]);

  const rows = useMemo(() => {
    const q = query.trim().toLowerCase();
    const filtered = trades.filter((t) => {
      if (side !== "all" && t.side !== side) return false;
      if (asset !== "all" && t.asset !== asset) return false;
      if (!q) return true;
      const blob = `${t.asset} ${t.side} ${t.entryReason} ${t.exitReason}`.toLowerCase();
      return blob.includes(q);
    });
    filtered.sort((a, b) => {
      const av = a[sortKey];
      const bv = b[sortKey];
      if (typeof av === "number" && typeof bv === "number") return asc ? av - bv : bv - av;
      return asc ? String(av).localeCompare(String(bv)) : String(bv).localeCompare(String(av));
    });
    return filtered;
  }, [trades, query, side, asset, sortKey, asc]);

  function header(key: SortKey, label: string) {
    return (
      <th className="whitespace-nowrap px-3 py-2 text-left font-semibold">
        <button
          type="button"
          className="inline-flex min-h-9 items-center"
          onClick={() => {
            if (sortKey === key) setAsc(!asc);
            else {
              setSortKey(key);
              setAsc(key === "asset" || key === "side");
            }
          }}
        >
          {label}
          {sortKey === key ? (asc ? " ↑" : " ↓") : ""}
        </button>
      </th>
    );
  }

  return (
    <div className="space-y-3">
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
        <input
          type="search"
          placeholder="Filter reason, asset..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <select value={asset} onChange={(e) => setAsset(e.target.value)}>
          <option value="all">All assets</option>
          {assets.map((a) => (
            <option key={a} value={a}>
              {a}
            </option>
          ))}
        </select>
        <select value={side} onChange={(e) => setSide(e.target.value as "all" | "buy" | "sell")}>
          <option value="all">All directions</option>
          <option value="buy">Buy / Long</option>
          <option value="sell">Sell / Short</option>
        </select>
      </div>
      <div className="card overflow-x-auto">
        <table className="min-w-[1100px] w-full text-sm">
          <thead style={{ color: "var(--muted)" }}>
            <tr className="border-b" style={{ borderColor: "var(--line)" }}>
              {header("exitTime", "Date/time")}
              {header("asset", "Asset")}
              {header("side", "Direction")}
              {header("entry", "Entry")}
              {header("exit", "Exit")}
              {header("positionSize", "Position")}
              {header("fees", "Fees")}
              {header("slippage", "Slippage")}
              {header("grossPnl", "Gross P/L")}
              {header("netPnl", "Net P/L")}
              {header("balanceAfter", "Balance after")}
              <th className="px-3 py-2 text-left font-semibold">Entry reason</th>
              <th className="px-3 py-2 text-left font-semibold">Exit reason</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.id} className="border-b" style={{ borderColor: "var(--line)" }}>
                <td className="whitespace-nowrap px-3 py-2">{when(t.exitTime)}</td>
                <td className="px-3 py-2 font-semibold">{t.asset}</td>
                <td className="px-3 py-2">{sideLabel(t.side)}</td>
                <td className="tabular px-3 py-2">{num(t.entry, 4)}</td>
                <td className="tabular px-3 py-2">{num(t.exit, 4)}</td>
                <td className="tabular px-3 py-2">{eur(t.positionSize)}</td>
                <td className="tabular px-3 py-2">{eur(t.fees)}</td>
                <td className="tabular px-3 py-2">{num(t.slippage, 4)}</td>
                <td className={`tabular px-3 py-2 ${pnlClass(t.grossPnl)}`}>{eur(t.grossPnl)}</td>
                <td className={`tabular px-3 py-2 ${pnlClass(t.netPnl)}`}>{eur(t.netPnl)}</td>
                <td className="tabular px-3 py-2">{eur(t.balanceAfter)}</td>
                <td className="max-w-[220px] px-3 py-2 text-xs" style={{ color: "var(--muted)" }}>
                  {t.entryReason}
                </td>
                <td className="max-w-[220px] px-3 py-2 text-xs" style={{ color: "var(--muted)" }}>
                  {t.exitReason}
                </td>
              </tr>
            ))}
            {rows.length === 0 ? (
              <tr>
                <td colSpan={13} className="px-3 py-8 text-center" style={{ color: "var(--muted)" }}>
                  No paper trades match these filters.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
      <p className="text-xs" style={{ color: "var(--muted)" }}>
        Showing {rows.length} of {trades.length} closed paper trades. Swipe horizontally on a phone.
      </p>
    </div>
  );
}
